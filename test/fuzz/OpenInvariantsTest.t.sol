// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";
import {StdInvariant} from "../../lib/forge-std/src/StdInvariant.sol";
import {DeployDSC} from "../../script/DeployDSC.s.sol";
import {DSCEngine} from "../../src/DSCEngine.sol";
import {DecentralizedStableCoin} from "../../src/DecentralizedStableCoin.sol";
import {HelperConfig} from "../../script/helperConfig.s.sol";
import {IERC20} from "../../lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";

contract OpenInvariantsTest is StdInvariant, Test {
// DeployDSC deployer;
// DSCEngine dsce;
// DecentralizedStableCoin dsc;
// HelperConfig helperConfig;
// address weth;
// address wbtc;

// function setUp() external{
//     deployer = new DeployDSC();
//     (dsc, dsce, helperConfig) = deployer.run();
//     (,, weth, wbtc,) = helperConfig.activeNetworkConfig();
//     targetContract(address(dsce));
// }

// function invariant_protocolMustHabeMoreValueThanTotalSupply() public view{
//     uint256 totalSupply = dsc.totalSupply();
//     uint256 totalWethDeposited = IERC20(weth).balanceOf(address(dsce));
//     uint256 totalBtcDeposited = IERC20(wbtc).balanceOf(address(dsce));

//     uint256 wethValue = dsce.getUsdValue(weth, totalWethDeposited);
//     uint256 wbtcValue = dsce.getUsdValue(wbtc, totalBtcDeposited);

//     assert(wethValue + wbtcValue >= totalSupply);
// }
}