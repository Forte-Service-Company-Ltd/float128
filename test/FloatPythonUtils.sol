/// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

import "forge-std/Test.sol";

contract FloatPythonUtils is Test {
    function _buildFFIMul128(
        int aMan,
        int aExp,
        int bMan,
        int bExp
    ) internal pure returns (string[] memory) {
        string[] memory inputs = new string[](6);
        inputs[0] = "python3";
        inputs[1] = "script/mul.py";
        inputs[2] = vm.toString(aMan);
        inputs[3] = vm.toString(aExp);
        inputs[4] = vm.toString(bMan);
        inputs[5] = vm.toString(bExp);
        return inputs;
    }
}
