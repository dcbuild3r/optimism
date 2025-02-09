// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { Predeploys } from "../libraries/Predeploys.sol";
import { L2CrossDomainMessenger } from "./L2CrossDomainMessenger.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title CrossDomainOwnable2
 * @notice This contract extends the OpenZeppelin `Ownable` contract for L2 contracts to be owned
 *         by contracts on L1. Note that this contract is meant to be used with systems that use
 *         the CrossDomainMessenger system. It will not work if the OptimismPortal is used
 *         directly.
 */
abstract contract CrossDomainOwnable3 is Ownable {
    /**
     * @notice If true, the contract uses the cross domain _checkOwner function override. If false
     *         it uses the standard Ownable _checkOwner function.
     */
    bool internal isLocal = true;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner,
        bool isLocal
    );

    /**
     * @notice Overrides the implementation of the `onlyOwner` modifier to check that the unaliased
     *         `xDomainMessageSender` is the owner of the contract. This value is set to the caller
     *         of the L1CrossDomainMessenger.
     */
    function _checkOwner() internal view override {
        if (isLocal) {
            require(owner() == _msgSender(), "CrossDomainOwnable3: caller is not the owner");
        } else {
            L2CrossDomainMessenger messenger = L2CrossDomainMessenger(
                Predeploys.L2_CROSS_DOMAIN_MESSENGER
            );

            require(
                msg.sender == address(messenger),
                "CrossDomainOwnable3: caller is not the messenger"
            );

            require(
                owner() == messenger.xDomainMessageSender(),
                "CrossDomainOwnable3: caller is not the owner"
            );
        }
    }

    /**
     * @notice Overrides the implementation of the `transferOwnership` function to allow
     * for local ownership.
     * @param _owner The new owner of the contract.
     * @param _isLocal If false, the contract uses the cross domain _checkOwner function override.
     * If false it uses the standard Ownable _checkOwner function.
     */
    function transferOwnership(address _owner, bool _isLocal) external {
        require(_owner != address(0), "CrossDomainOwnable3: new owner is the zero address");

        address oldOwner = owner();

        super.transferOwnership(_owner);

        emit OwnershipTransferred(oldOwner, _owner, _isLocal);

        isLocal = _isLocal;
    }
}
