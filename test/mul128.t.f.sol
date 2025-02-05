/// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

import "forge-std/console2.sol";
import "src/float128.sol";
import "test/FloatPythonUtils.sol";

contract Mul128FuzzTest is FloatPythonUtils {
    function testMul128Fuzz(int aMan, int aExp, int bMan, int bExp) public {
        aMan = bound(aMan, 10, 10 ** 32);
        aExp = -2; // bound(aExp, -10, 10);
        bMan = bound(bMan, 10, 10 ** 32);
        bExp = -3; //bound(bExp, -10, 10);
        bool isNegativePy;
        int256 resPy;

        string[] memory inputs = _buildFFIMul128(aMan, aExp, bMan, bExp);
        bytes memory res = vm.ffi(inputs);
        (resPy) = abi.decode((res), (int256));
        console2.log("Before mul");

        (int resSol, int resExp) = Float2Ints.mul128(aMan, aExp, bMan, bExp);
        //resSol = resSol * 10 >> resExp;
        console2.log("PyRes: ", resPy);
        console2.log("solRes: ", resSol);
        assertEq(resPy, resSol);
        //assertEq(isNegativePy, isNegativeSol);
    }
}
