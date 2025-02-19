/// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Test.sol";

contract FloatPythonUtils is Test {
    function _buildFFIMul128(int aMan, int aExp, int bMan, int bExp, string memory operation) internal pure returns (string[] memory) {
        string[] memory inputs = new string[](7);
        inputs[0] = "python3";
        inputs[1] = "script/float128_test.py";
        inputs[2] = vm.toString(aMan);
        inputs[3] = vm.toString(aExp);
        inputs[4] = vm.toString(bMan);
        inputs[5] = vm.toString(bExp);
        inputs[6] = operation;
        return inputs;
    }
}
