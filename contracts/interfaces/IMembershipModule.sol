// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.24;

interface IMembershipModule {
    event MembershipIssued(uint256 indexed poolId, address indexed to, uint256 indexed tokenId, uint64 mintedAt);
    event PoolMinterUpdated(address indexed minter, bool allowed);
    event PoolBaseURISet(uint256 indexed poolId, string baseURI);
    event AdminUpdated(address indexed oldAdmin, address indexed newAdmin);

    function hasMembership(uint256 poolId, address user) external view returns (bool);
    function mintedAt(uint256 poolId, address user) external view returns (uint64);
    function membershipTokenId(uint256 poolId, address user) external view returns (uint256);
    function isPoolMinter(address minter) external view returns (bool);

    function mintMembership(uint256 poolId, address to) external returns (uint256 tokenId);
    function setPoolMinter(address minter, bool allowed) external;
    function setPoolBaseURI(uint256 poolId, string calldata baseURI) external;

    function factory() external view returns (address);
    function admin() external view returns (address);
}
