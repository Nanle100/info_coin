// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import {DataPackageManager} from "../src/infocoin.sol";

contract DataPackageManagerScript is Script {
    DataPackageManager public dataPackageManager;

    function setUp() public {}

    function run() public {
        vm.startBroadcast();

        dataPackageManager = new DataPackageManager(
            0xdAC17F958D2ee523a2206206994597C13D831ec7
        );

        vm.stopBroadcast();
    }
}
