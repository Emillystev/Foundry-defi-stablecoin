// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import {Test, console} from "forge-std/Test.sol";
import {DSCEngine} from "../../src/DSCEngine.sol";
import {DeployDSC} from "../../script/DeployDSC.s.sol";
import {DecentralizedStableCoin} from "../../src/DecentralizedStableCoin.sol";
import {HelperConfig} from "../../script/HelperConfig.s.sol";
import {ERC20Mock} from "../../lib/openzeppelin-contracts/contracts/mocks/ERC20Mock.sol";
import {MockV3Aggregator} from "../mocks/MockV3Aggregator.sol";

contract DSCEngineTest is Test {
    DeployDSC deployer;
    DecentralizedStableCoin dsc;
    DSCEngine dsce;
    HelperConfig helperConfig;
    address ethUsdPriceFeed;
    address public btcUsdPriceFeed;
    address weth;
    address wbtc;

    address[] public tokenAddresses;
    address[] public priceFeedAddresses;

    address public user = address(1);
    address public USER = makeAddr("user");
    uint256 public amountCollateral = 10 ether;
    uint256 public constant AMOUNT_COLLATERAL = 10e18;
    uint256 public constant STARTING_ERC20_BALANCE = 10 ether;
    uint256 amountToMint = 100 ether;

    event CollateralRedeemed(
        address indexed redeemedFrom, address indexed redeemedTo, address indexed token, uint256 amount
    );

    function setUp() external {
        deployer = new DeployDSC();
        (dsc, dsce, helperConfig) = deployer.run();
        (ethUsdPriceFeed, btcUsdPriceFeed, weth, wbtc,) = helperConfig.activeNetworkConfig();

        ERC20Mock(weth).mint(USER, STARTING_ERC20_BALANCE);
    }

    /////////////////////////

    // constructor
    function testRevertsIfTokenLengthDoesntMatchPriceFeeds() external {
        vm.startPrank(USER);
        tokenAddresses.push(weth);
        priceFeedAddresses.push(ethUsdPriceFeed);
        priceFeedAddresses.push(btcUsdPriceFeed);
        vm.expectRevert(DSCEngine.DSCEngine__TokenAddressesAndPriceFeedAddressesMustBeSameLength.selector);
        new DSCEngine(tokenAddresses, priceFeedAddresses, address(dsce));
    }
    /////////////////////////

    function testGetUsdValue() public view {
        uint256 ethAmount = 15e18;
        uint256 expectedUsd = 30000e18; // 15e18 times 2000e8
        uint256 actualUsd = dsce.getUsdValue(weth, ethAmount);
        assertEq(expectedUsd, actualUsd);
    }

    function testRevertsIfCollateralZero() public {
        vm.startPrank(USER);
        ERC20Mock(weth).approve(address(dsce), AMOUNT_COLLATERAL);
        vm.expectRevert(DSCEngine.DSCEngine__NeedsMoreThanZero.selector);
        dsce.depositCollateral(weth, 0);
        vm.stopPrank();
    }

    function testRevertsIfRedeemCollateralZero() external {
        vm.prank(USER);
        vm.expectRevert(DSCEngine.DSCEngine__NeedsMoreThanZero.selector);
        dsce.redeemCollateral(weth, 0);
    }

    /////////////////////
    function testRevertsWithUnapprovedCollateral() external {
        ERC20Mock ranToken = new ERC20Mock("RAN", "RAN", USER, AMOUNT_COLLATERAL);
        vm.startPrank(USER);
        vm.expectRevert(DSCEngine.DSCEngine__NotAllowedToken.selector);
        dsce.depositCollateral(address(ranToken), AMOUNT_COLLATERAL);
        vm.stopPrank();
    }

    function testGetTokenAmountFromUsd() external view {
        uint256 usdAmount = 100 ether;
        uint256 expectedWeth = 0.05 ether;
        uint256 actualWeth = dsce.getTokenAmountFromUsd(weth, usdAmount);
        assertEq(expectedWeth, actualWeth);
    }
    /////////////////////

    modifier depositCollateral() {
        vm.startPrank(USER);
        ERC20Mock(weth).approve(address(dsce), AMOUNT_COLLATERAL);
        dsce.depositCollateral(weth, AMOUNT_COLLATERAL);
        vm.stopPrank();
        _;
    }

    //
    function testCanDepositCollateralAndGetAccountInfo() external depositCollateral {
        (uint256 totalDscMinted, uint256 collateralValueInUsd) = dsce.getAccountInformation(USER);

        uint256 expectedtotalDscMinted = 0;
        uint256 expectedDepositAmount = dsce.getTokenAmountFromUsd(weth, collateralValueInUsd);
        console.log(expectedDepositAmount);
        assertEq(totalDscMinted, expectedtotalDscMinted);
        assertEq(expectedDepositAmount, amountCollateral);
    }

    function testRevertsIfMintedDscBreaksHealthFactor() public {
        (, int256 price,,,) = MockV3Aggregator(ethUsdPriceFeed).latestRoundData();
        amountToMint = (amountCollateral * (uint256(price) * dsce.getAdditionalFeedPrecision())) / dsce.getPrecision();
        vm.startPrank(USER);
        ERC20Mock(weth).approve(address(dsce), amountCollateral);

        uint256 expectedHealthFactor =
            dsce.calculateHealthFactor(amountToMint, dsce.getUsdValue(weth, amountCollateral));
        vm.expectRevert(abi.encodeWithSelector(DSCEngine.DSCEngine__BreaksHealthFactor.selector, expectedHealthFactor));
        dsce.depositCollateralAndMintDsc(weth, amountCollateral, amountToMint);
        vm.stopPrank();
    }
}
