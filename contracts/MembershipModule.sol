// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.24;

import {IMembershipModule} from "./interfaces/IMembershipModule.sol";

/// @notice Pool-scoped membership NFT registry. Mints driven by authorized pools or admin.
contract MembershipModule is IMembershipModule {
    error NotAdmin();
    error NotFactory();
    error NotAuthorized();
    error ZeroAddress();
    error AlreadyHasMembership(uint256 poolId, address user);
    error TokenDoesNotExist(uint256 tokenId);
    error NotTokenOwner(address from, uint256 tokenId);

    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    address public override admin;
    address public immutable override factory;

    string public name;
    string public symbol;
    uint256 private _nextTokenId = 1;

    mapping(uint256 => mapping(address => uint256)) private _poolMemberTokenId;
    mapping(uint256 => mapping(address => uint64))  private _mintedAt;
    mapping(uint256 => uint256) private _tokenPool;
    mapping(uint256 => string)  private _poolBaseURI;

    mapping(uint256 => address) private _ownerOf;
    mapping(address => uint256) private _balanceOf;
    mapping(uint256 => address) private _tokenApprovals;
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    mapping(address => bool) public override isPoolMinter;

    modifier onlyAdmin()   { if (msg.sender != admin)   revert NotAdmin();   _; }
    modifier onlyFactory() { if (msg.sender != factory) revert NotFactory(); _; }
    modifier onlyAuthorizedMinter() {
        if (msg.sender != admin && !isPoolMinter[msg.sender]) revert NotAuthorized();
        _;
    }

    constructor(string memory name_, string memory symbol_, address initialAdmin, address factory_) {
        if (initialAdmin == address(0) || factory_ == address(0)) revert ZeroAddress();
        admin   = initialAdmin;
        factory = factory_;
        name    = name_;
        symbol  = symbol_;
    }

    // ===== Auth-gated mint =====

    function mintMembership(uint256 poolId, address to) external override onlyAuthorizedMinter returns (uint256 tokenId) {
        if (to == address(0)) revert ZeroAddress();
        if (_poolMemberTokenId[poolId][to] != 0) revert AlreadyHasMembership(poolId, to);

        tokenId = _nextTokenId++;
        _ownerOf[tokenId] = to;
        _balanceOf[to]   += 1;
        _tokenPool[tokenId] = poolId;
        _poolMemberTokenId[poolId][to] = tokenId;
        _mintedAt[poolId][to] = uint64(block.timestamp);

        emit Transfer(address(0), to, tokenId);
        emit MembershipIssued(poolId, to, tokenId, _mintedAt[poolId][to]);
    }

    function setPoolMinter(address minter, bool allowed) external override onlyFactory {
        if (minter == address(0)) revert ZeroAddress();
        isPoolMinter[minter] = allowed;
        emit PoolMinterUpdated(minter, allowed);
    }

    function setPoolBaseURI(uint256 poolId, string calldata baseURI) external override onlyAdmin {
        _poolBaseURI[poolId] = baseURI;
        emit PoolBaseURISet(poolId, baseURI);
    }

    function setAdmin(address newAdmin) external onlyAdmin {
        if (newAdmin == address(0)) revert ZeroAddress();
        admin = newAdmin;
    }

    // ===== Views =====

    function hasMembership(uint256 poolId, address user) external view override returns (bool) {
        return _poolMemberTokenId[poolId][user] != 0;
    }

    function mintedAt(uint256 poolId, address user) external view override returns (uint64) {
        return _mintedAt[poolId][user];
    }

    function membershipTokenId(uint256 poolId, address user) external view override returns (uint256) {
        return _poolMemberTokenId[poolId][user];
    }

    function tokenURI(uint256 tokenId) external view returns (string memory) {
        if (_ownerOf[tokenId] == address(0)) revert TokenDoesNotExist(tokenId);
        uint256 pId = _tokenPool[tokenId];
        return string(abi.encodePacked(_poolBaseURI[pId], _toString(tokenId)));
    }

    function ownerOf(uint256 tokenId) public view returns (address) {
        address o = _ownerOf[tokenId];
        if (o == address(0)) revert TokenDoesNotExist(tokenId);
        return o;
    }

    function balanceOf(address user) external view returns (uint256) {
        if (user == address(0)) revert ZeroAddress();
        return _balanceOf[user];
    }

    function poolOfToken(uint256 tokenId) external view returns (uint256) {
        if (_ownerOf[tokenId] == address(0)) revert TokenDoesNotExist(tokenId);
        return _tokenPool[tokenId];
    }

    // ===== ERC721 transfer surface =====

    function approve(address to, uint256 tokenId) external {
        address o = ownerOf(tokenId);
        if (msg.sender != o && !_operatorApprovals[o][msg.sender]) revert NotAuthorized();
        _tokenApprovals[tokenId] = to;
        emit Approval(o, to, tokenId);
    }

    function getApproved(uint256 tokenId) external view returns (address) {
        if (_ownerOf[tokenId] == address(0)) revert TokenDoesNotExist(tokenId);
        return _tokenApprovals[tokenId];
    }

    function setApprovalForAll(address operator, bool approved) external {
        _operatorApprovals[msg.sender][operator] = approved;
        emit ApprovalForAll(msg.sender, operator, approved);
    }

    function isApprovedForAll(address o, address op) external view returns (bool) {
        return _operatorApprovals[o][op];
    }

    function transferFrom(address from, address to, uint256 tokenId) public {
        if (to == address(0)) revert ZeroAddress();
        address o = ownerOf(tokenId);
        if (o != from) revert NotTokenOwner(from, tokenId);
        if (msg.sender != o && msg.sender != _tokenApprovals[tokenId]
            && !_operatorApprovals[o][msg.sender]) revert NotAuthorized();

        uint256 pId = _tokenPool[tokenId];
        if (_poolMemberTokenId[pId][to] != 0) revert AlreadyHasMembership(pId, to);

        _tokenApprovals[tokenId] = address(0);
        _poolMemberTokenId[pId][from] = 0;
        _poolMemberTokenId[pId][to]   = tokenId;
        // mintedAt stays anchored to the original mint timestamp — transferring an NFT does not give the recipient
        // "pre-round" status. Anti-gaming property.

        _ownerOf[tokenId] = to;
        _balanceOf[from] -= 1;
        _balanceOf[to]   += 1;

        emit Approval(from, address(0), tokenId);
        emit Transfer(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) external { transferFrom(from, to, tokenId); }
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata) external { transferFrom(from, to, tokenId); }

    function supportsInterface(bytes4 interfaceId) external pure returns (bool) {
        return interfaceId == 0x80ac58cd // ERC721
            || interfaceId == 0x5b5e139f // ERC721Metadata
            || interfaceId == 0x01ffc9a7 // ERC165
            || interfaceId == type(IMembershipModule).interfaceId;
    }

    function _toString(uint256 v) private pure returns (string memory) {
        if (v == 0) return "0";
        uint256 t = v;
        uint256 d;
        while (t != 0) { d++; t /= 10; }
        bytes memory b = new bytes(d);
        while (v != 0) { d -= 1; b[d] = bytes1(uint8(48 + uint256(v % 10))); v /= 10; }
        return string(b);
    }
}
