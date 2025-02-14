// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.24;
import "forge-std/console2.sol";

type packedFloat is uint256;

struct Float {
    int significand;
    int exponent;
}

library Float128{
    /************************************************************************************************************
     * Bitmap:                                                                                                  *
     * 255 ... UNUSED ... 138, 137 ... EXPONENT ... 129, MANTISSA_SIGN (128), 127 .. MANTISSA ... 0             *
     * The exponent is signed using the offset zero to 256. max values: -256 and +255. Plenty for our case      *
     ************************************************************************************************************/
    uint constant MANTISSA_MASK = 0xffffffffffffffffffffffffffffffff;
    uint constant MANTISSA_SIGN_MASK = 0x100000000000000000000000000000000;
    uint constant EXPONENT_MASK = 0xfffffffffffffffffffffffffffffffe00000000000000000000000000000000;
    uint constant TOW_COMPLEMENT_SIGN_MASK = 0x8000000000000000000000000000000000000000000000000000000000000000;
    uint constant BASE = 10;
    uint constant ZERO_OFFSET = 256;
    uint constant ZERO_OFFSET_MINUS_1 = 255;
    uint constant EXPONENT_BIT = 129;
    uint constant MAX_DIGITS = 38;
    uint constant MAX_DIGITS_MINUS_1 = 37;
    uint constant MAX_DIGITS_PLUS_1 = 39;
    uint constant MAX_DIGITS_X_2 = 76;
    uint constant MAX_DIGITS_X_2_MINUS_1 = 75;
    uint constant MAX_DIGITS_X_2_PLUS_1 = 77;
    uint constant MAX_38_DIGIT_NUMBER = 99999999999999999999999999999999999999;
    uint constant MIN_38_DIGIT_NUMBER = 10000000000000000000000000000000000000;
    uint constant MAX_39_DIGIT_NUMBER = 999999999999999999999999999999999999999;
    uint constant MAX_75_DIGIT_NUMBER = 999999999999999999999999999999999999999999999999999999999999999999999999999;
    uint constant MAX_76_DIGIT_NUMBER = 9999999999999999999999999999999999999999999999999999999999999999999999999999;

    function add(packedFloat a, packedFloat b) internal pure returns (packedFloat r) {
        uint addition;
        bool isSubtraction;
        bool sameExponent;
        assembly {
            // we extract the exponent and mantissas for both
            let aExp := and(a, EXPONENT_MASK)
            let bExp := and(b, EXPONENT_MASK)
            let aMan := and(a, MANTISSA_MASK)
            let bMan := and(b, MANTISSA_MASK)
            // we adjust the significant digits and set the exponent of the result. we add 38 digits of precision
            if gt(aExp, bExp) {
                r := sub(aExp, shl(EXPONENT_BIT, MAX_DIGITS))
                let adj := sub(shr(EXPONENT_BIT, r), shr(EXPONENT_BIT, bExp))
                let neg := and(TOW_COMPLEMENT_SIGN_MASK, adj)
                if neg{
                    bMan := mul(bMan, exp(BASE, sub(0, adj)))
                }
                if iszero(neg){
                    bMan := div(bMan, exp(BASE, adj))
                }
                aMan := mul(aMan, exp(BASE, MAX_DIGITS))
            }
            if gt(bExp, aExp) {
                r := sub(bExp, shl(EXPONENT_BIT, MAX_DIGITS))
                let adj := sub(shr(EXPONENT_BIT, r), shr(EXPONENT_BIT, aExp))
                let neg := and(TOW_COMPLEMENT_SIGN_MASK, adj)
                if neg{
                    aMan := mul(aMan, exp(BASE, sub(0, adj)))
                }
                if iszero(neg){
                    aMan := div(aMan, exp(BASE, adj))
                }
                bMan := mul(bMan, exp(BASE, MAX_DIGITS))
            }
            if eq(aExp, bExp) {
                r := aExp
                sameExponent := 1
            }
            // we use complements 2 for mantissa sign
            if and(a, MANTISSA_SIGN_MASK) {
                aMan := sub(0,aMan)
            }
            if and(b, MANTISSA_SIGN_MASK) {
                bMan := sub(0,bMan)
            }
            addition := add(aMan, bMan)
            isSubtraction := xor(and(a, MANTISSA_SIGN_MASK), and(b, MANTISSA_SIGN_MASK))

            if and(TOW_COMPLEMENT_SIGN_MASK, addition) {
                r := or(r, MANTISSA_SIGN_MASK) // assign the negative sign
                addition := sub(0,addition) // convert back from 2's complement
            }
        }
        if( addition == 0){
            assembly{
                r := 0
            }
        }else{
            if(isSubtraction){
                if(addition > MAX_38_DIGIT_NUMBER || addition < MIN_38_DIGIT_NUMBER){
                    uint digitsMantissa = findNumberOfDigits(addition);
                    assembly{
                        let mantissaReducer := sub(digitsMantissa, MAX_DIGITS)
                        let negativeReducer := and(TOW_COMPLEMENT_SIGN_MASK, mantissaReducer)
                        if negativeReducer{
                            addition := mul(addition,exp(BASE, sub(0, mantissaReducer))) 
                            r := sub(r, shl(EXPONENT_BIT, sub(0, mantissaReducer)))
                        }
                        if iszero(negativeReducer){
                            addition := div(addition,exp(BASE, mantissaReducer))
                            r := add(r, shl(EXPONENT_BIT, mantissaReducer))
                        }
                        r := or(r, addition)
                    }
                }else{
                    assembly{
                        r := or(r, addition)
                    }
                }
            }else{
                assembly{
                    if iszero(sameExponent){
                        let is77digit := gt(addition, MAX_76_DIGIT_NUMBER)
                        if is77digit{
                            addition := div(addition,exp(BASE, MAX_DIGITS_PLUS_1))
                            r := add(r, shl(EXPONENT_BIT, MAX_DIGITS_PLUS_1))
                        }
                        if iszero(is77digit){
                            addition := div(addition,exp(BASE, MAX_DIGITS))
                            r := add(r, shl(EXPONENT_BIT, MAX_DIGITS))
                        }
                    }
                    if sameExponent{
                        if gt(addition, MAX_38_DIGIT_NUMBER){
                            addition := div(addition,BASE)
                            r := add(r, shl(EXPONENT_BIT, 1))
                        }
                    }
                    r := or(r, addition)
                }
            }
        }
    }

    function sub(packedFloat a, packedFloat b) internal pure returns (packedFloat r) {
        uint addition;
        bool isSubtraction;
        bool sameExponent;
        assembly {
            // we extract the exponent and mantissas for both
            let aExp := and(a, EXPONENT_MASK)
            let bExp := and(b, EXPONENT_MASK)
            let aMan := and(a, MANTISSA_MASK)
            let bMan := and(b, MANTISSA_MASK)
            // we adjust the significant digits and set the exponent of the result. we add 38 digits of precision
            if gt(aExp, bExp) {
                r := sub(aExp, shl(EXPONENT_BIT, MAX_DIGITS))
                let adj := sub(shr(EXPONENT_BIT, r), shr(EXPONENT_BIT, bExp))
                let neg := and(TOW_COMPLEMENT_SIGN_MASK, adj)
                if neg{
                    bMan := mul(bMan, exp(BASE, sub(0, adj)))
                }
                if iszero(neg){
                    bMan := div(bMan, exp(BASE, adj))
                }
                aMan := mul(aMan, exp(BASE, MAX_DIGITS))
            }
            if gt(bExp, aExp) {
                r := sub(bExp, shl(EXPONENT_BIT, MAX_DIGITS))
                let adj := sub(shr(EXPONENT_BIT, r), shr(EXPONENT_BIT, aExp))
                let neg := and(TOW_COMPLEMENT_SIGN_MASK, adj)
                if neg{
                    aMan := mul(aMan, exp(BASE, sub(0, adj)))
                }
                if iszero(neg){
                    aMan := div(aMan, exp(BASE, adj))
                }
                bMan := mul(bMan, exp(BASE, MAX_DIGITS))
            }
            if eq(aExp, bExp) {
                r := aExp
                sameExponent := 1
            }
            // we use complements 2 for mantissa sign
            if and(a, MANTISSA_SIGN_MASK) {
                aMan := sub(0,aMan)
            }
            if iszero(and(b, MANTISSA_SIGN_MASK)) {
                bMan := sub(0,bMan)
            }
            addition := add(aMan, bMan)
            isSubtraction := eq(and(a, MANTISSA_SIGN_MASK), and(b, MANTISSA_SIGN_MASK))

            if and(TOW_COMPLEMENT_SIGN_MASK, addition) {
                r := or(r, MANTISSA_SIGN_MASK) // assign the negative sign
                addition := sub(0,addition) // convert back from 2's complement
            }
        }
        if( addition == 0){
            assembly{
                r := 0
            }
        }else{
            if(isSubtraction){
                if(addition > MAX_38_DIGIT_NUMBER || addition < MIN_38_DIGIT_NUMBER){
                    uint digitsMantissa = findNumberOfDigits(addition);
                    assembly{
                        let mantissaReducer := sub(digitsMantissa, MAX_DIGITS)
                        let negativeReducer := and(TOW_COMPLEMENT_SIGN_MASK, mantissaReducer)
                        if negativeReducer{
                            addition := mul(addition,exp(BASE, sub(0, mantissaReducer))) 
                            r := sub(r, shl(EXPONENT_BIT, sub(0, mantissaReducer)))
                        }
                        if iszero(negativeReducer){
                            addition := div(addition,exp(BASE, mantissaReducer))
                            r := add(r, shl(EXPONENT_BIT, mantissaReducer))
                        }
                        r := or(r, addition)
                    }
                }else{
                    assembly{
                        r := or(r, addition)
                    }
                }
            }else{
                assembly{
                    if iszero(sameExponent){
                        let is77digit := gt(addition, MAX_76_DIGIT_NUMBER)
                        if is77digit{
                            addition := div(addition,exp(BASE, MAX_DIGITS_PLUS_1))
                            r := add(r, shl(EXPONENT_BIT, MAX_DIGITS_PLUS_1))
                        }
                        if iszero(is77digit){
                            addition := div(addition,exp(BASE, MAX_DIGITS))
                            r := add(r, shl(EXPONENT_BIT, MAX_DIGITS))
                        }
                    }
                    if sameExponent{
                        if gt(addition, MAX_38_DIGIT_NUMBER){
                            addition := div(addition,BASE)
                            r := add(r, shl(EXPONENT_BIT, 1))
                        }
                    }
                    r := or(r, addition)
                }
            }
        }
    }

    function mul(packedFloat a, packedFloat b) internal pure returns (packedFloat r) {
        uint rMan;
        uint rExp;
        assembly {
            // if any of the elements is zero then the result will be zero
            if iszero(or(iszero(a), iszero(b))){
                // we extract the exponent and mantissas for both
                let aExp := and(a, EXPONENT_MASK)
                let bExp := and(b, EXPONENT_MASK)
                let aMan := and(a, MANTISSA_MASK)
                let bMan := and(b, MANTISSA_MASK)
        
                rMan := mul(aMan, bMan)
                rExp := sub(add(shr(EXPONENT_BIT, aExp), shr(EXPONENT_BIT, bExp)), ZERO_OFFSET)
                // multiplication between 2 numbers with k digits can result in a number between 2*k - 1 and 2*k digits
                // we check first if rMan is a 2k-digit number
                let is76digit := gt(rMan, MAX_75_DIGIT_NUMBER)
                if is76digit {
                    rMan := div(rMan, exp(BASE, MAX_DIGITS))
                    rExp := add(rExp, MAX_DIGITS)
                }
                // if not, we then know that it is a 2k-1-digit number
                if iszero(is76digit) {
                    rMan := div(rMan, exp(BASE, MAX_DIGITS_MINUS_1))
                    rExp := add(rExp, MAX_DIGITS_MINUS_1)
                }
                r :=  or(xor(and(a, MANTISSA_SIGN_MASK), and(b, MANTISSA_SIGN_MASK)),or(rMan,shl(EXPONENT_BIT, rExp)))
            }
        }
    }

    function div(packedFloat a, packedFloat b) internal pure returns(packedFloat r){
        assembly{
            // if a is zero then the result will be zero
            if gt(a, 0){
                let aMan := and(a, MANTISSA_MASK)
                let aExp := shr(EXPONENT_BIT, and(a, EXPONENT_MASK))
                let bMan := and(b, MANTISSA_MASK)
                let bExp :=  shr(EXPONENT_BIT, and(b, EXPONENT_MASK))
                // we can add 39 digits since we have extra room in the bits for one more digit
                aMan := mul(aMan, exp(BASE, MAX_DIGITS))
                aExp := sub(aExp,  MAX_DIGITS)
                let rMan := div(aMan, bMan)

                let rExp := sub(add(aExp, ZERO_OFFSET), bExp)
                // a division between a k-digit number and a j-digit number will result in a number between (k - j) 
                // and (k - j + 1) digits. Since we are dividing a 76-digit number by a 38-digit number, we know 
                // that the result could have either 39 or 38 digitis.
                let is39digit := gt(rMan, MAX_38_DIGIT_NUMBER)
                if is39digit {
                    // we need to truncate the 2 last digits
                    rExp := add(rExp, 1)
                    rMan := div(rMan, exp(BASE, 1))
                }
                r :=  or(xor(and(a, MANTISSA_SIGN_MASK), and(b, MANTISSA_SIGN_MASK)),or(rMan,shl(EXPONENT_BIT, rExp)))
            }
        }
    }

    function add(Float memory a, Float memory b) internal pure returns (Float memory r) {
        unchecked{
            bool isSubtraction = (uint(a.significand) >> 255) ^ (uint(b.significand) >> 255) > 0;
            bool sameExponent;
            // increase precision and adjust significands according to their exponent
            if(a.exponent > b.exponent){
                r.exponent = a.exponent - int(MAX_DIGITS);
                int adj = r.exponent - b.exponent;
                if(adj < 0) b.significand *= int(BASE**uint(adj * -1));
                else b.significand /= int(BASE**(uint(adj)));
                a.significand *= int(BASE**(MAX_DIGITS));
            }else if(a.exponent < b.exponent){
                r.exponent = b.exponent - int(MAX_DIGITS);
                int adj = r.exponent - a.exponent;
                if(adj < 0) a.significand *= int(BASE**uint(adj * -1));
                else a.significand /= int(BASE**(uint(adj)));
                b.significand *= int(BASE**(MAX_DIGITS));
            }else{
                r.exponent = a.exponent;
                sameExponent = true;
            }
            r.significand = a.significand + b.significand;
            // normalization
            if(r.significand == 0) r.exponent = -256;
            else{
                if(isSubtraction){
                    if(r.significand > int(MAX_38_DIGIT_NUMBER) || r.significand < int(MIN_38_DIGIT_NUMBER)){
                        uint digitsMantissa = findNumberOfDigits(r.significand < 0 ? uint(r.significand * -1) : uint(r.significand));
                        int mantissaReducer = int(digitsMantissa - MAX_DIGITS);
                        if(mantissaReducer < 0){
                            r.significand *= int(BASE**uint(mantissaReducer * -1));
                            r.exponent += mantissaReducer;
                        }else{
                            r.significand /= int(BASE**uint(mantissaReducer));
                            r.exponent += mantissaReducer;
                        }
                    }else return r;
                }else{
                    if(sameExponent){
                         if(r.significand > int(MAX_38_DIGIT_NUMBER) || r.significand < int(0-MAX_38_DIGIT_NUMBER)){
                            r.significand /= int(BASE);
                            ++r.exponent;
                        }
                    }else{
                        if(r.significand > int(MAX_76_DIGIT_NUMBER) || r.significand < int(0-MAX_76_DIGIT_NUMBER)){
                            r.significand /= int(BASE**MAX_DIGITS_PLUS_1);
                            r.exponent += int(MAX_DIGITS_PLUS_1);
                        }else{
                            r.significand /= int(BASE**MAX_DIGITS);
                            r.exponent += int(MAX_DIGITS);
                        }
                    }
                }
            }
        }
    }

    function sub(Float memory a, Float memory b) internal pure returns (Float memory r) {
        unchecked{
            bool isSubtraction = (uint(a.significand) >> 255) == (uint(b.significand) >> 255);
            bool sameExponent;
            // increase precision and adjust significands according to their exponent
            if(a.exponent > b.exponent){
                r.exponent = a.exponent - int(MAX_DIGITS);
                int adj = r.exponent - b.exponent;
                if(adj < 0) b.significand *= int(BASE**uint(adj * -1));
                else b.significand /= int(BASE**(uint(adj)));
                a.significand *= int(BASE**(MAX_DIGITS));
            }else if(a.exponent < b.exponent){
                r.exponent = b.exponent - int(MAX_DIGITS);
                int adj = r.exponent - a.exponent;
                if(adj < 0) a.significand *= int(BASE**uint(adj * -1));
                else a.significand /= int(BASE**(uint(adj)));
                b.significand *= int(BASE**(MAX_DIGITS));
            }else{
                r.exponent = a.exponent;
                sameExponent = true;
            }
            r.significand = a.significand - b.significand;
            // normalization
            if(r.significand == 0) r.exponent = -256;
            else{
                if(isSubtraction){
                    if(r.significand > int(MAX_38_DIGIT_NUMBER) || r.significand < int(MIN_38_DIGIT_NUMBER)){
                        uint digitsMantissa = findNumberOfDigits(r.significand < 0 ? uint(r.significand * -1) : uint(r.significand));
                        int mantissaReducer = int(digitsMantissa - MAX_DIGITS);
                        if(mantissaReducer < 0){
                            r.significand *= int(BASE**uint(mantissaReducer * -1));
                            r.exponent += mantissaReducer;
                        }else{
                            r.significand /= int(BASE**uint(mantissaReducer));
                            r.exponent += mantissaReducer;
                        }
                    }else return r;
                }else{
                    if(sameExponent){
                         if(r.significand > int(MAX_38_DIGIT_NUMBER) || r.significand < int(0-MAX_38_DIGIT_NUMBER)){
                            r.significand /= int(BASE);
                            ++r.exponent;
                        }
                    }else{
                        if(r.significand > int(MAX_76_DIGIT_NUMBER) || r.significand < int(0-MAX_76_DIGIT_NUMBER)){
                            r.significand /= int(BASE**MAX_DIGITS_PLUS_1);
                            r.exponent += int(MAX_DIGITS_PLUS_1);
                        }else{
                            r.significand /= int(BASE**MAX_DIGITS);
                            r.exponent += int(MAX_DIGITS);
                        }
                    }
                }
            }
        }
    }

    function mul(Float memory a, Float memory b) internal pure returns (Float memory r) {
        assembly {
            mstore(r, mul(mload(a), mload(b)))
            mstore(add(r, 0x20), add(mload(add(a, 0x20)), mload(add(b, 0x20))))
        }
        uint256 rawResultSize = findNumberOfDigits(uint(r.significand));
        assembly {
            if gt(rawResultSize, MAX_DIGITS) {
                let expReducer := sub(rawResultSize, MAX_DIGITS)
                mstore(r, div(mload(r), exp(BASE, expReducer)))
                mstore(add(r, 0x20), add(mload(add(r, 0x20)), expReducer))
            }
        }
        // unchecked{
        //     r.exponent = a.exponent + b.exponent;
        //     r.significand = a.significand * b.significand;
        //     uint256 rawResultSize = findNumberOfDigits(uint(r.significand));
        //     if(rawResultSize > MAX_DIGITS){
        //         uint expReducer = rawResultSize -  MAX_DIGITS;
        //         r.exponent += int(expReducer);
        //         r.significand /= int(10**expReducer);
        //     }
        // }
    }

    function div(Float memory a, Float memory b) internal pure returns (Float memory r) {
        bool negativeA;
        bool negativeB;
        assembly{
            if gt(shr(255,mload(a)),0){
                negativeA := 1
                mstore(a, sub(0,mload(a)))
            }
            if gt(shr(255,mload(b)),0){
                negativeB := 1
                mstore(b, sub(0,mload(b)))
            }
        }
        uint digitsA = findNumberOfDigits(uint(a.significand));
        assembly{
            let expMultiplier := sub(MAX_DIGITS_X_2_PLUS_1, digitsA)
            mstore(a, mul(mload(a), exp(BASE, expMultiplier)))
            let negExpMultiplier := sub(0,expMultiplier)
            mstore(add(a, 0x20), add(mload(add(a, 0x20)),  negExpMultiplier))
            mstore(r, div(mload(a), mload(b)))
            mstore(add(0x20, r), add(mload(add(0x20, a)), sub(0,mload(add(0x20, b)))))
        }
        uint rawResultSize = findNumberOfDigits(uint(r.significand));
        assembly{
            let expReducer := add(rawResultSize, sub(0,MAX_DIGITS))
            mstore(add(r, 0x20), add(mload(add(r, 0x20)), expReducer))
            if iszero(gt(shr(255,expReducer),0)){
                mstore(r, div(mload(r), exp(BASE, expReducer)))
            }
            if gt(shr(255,expReducer),0){
                expReducer := sub(0,expReducer)
                mstore(r, mul(mload(r), exp(BASE, expReducer)))
            }
            if xor(negativeA, negativeB){
                mstore(r, sub(0,mload(r)))
            }
        }
        // unchecked{
        //     /// this method can only have 37 digits of precision
        //     uint digitsA = findNumberOfDigits(uint(a.significand));
        //     uint expMultiplier = MAX_DIGITS_X_2 - digitsA;
        //     a.significand *= int(10**expMultiplier);
        //     a.exponent -= int(expMultiplier);
        //     r.exponent = a.exponent - b.exponent;
        //     r.significand = a.significand / b.significand;
        //     uint256 rawResultSize = findNumberOfDigits(uint(r.significand));
        //     int expReducer = int(rawResultSize) -  int(MAX_DIGITS);
        //     r.exponent += expReducer;
        //     if (expReducer >= 0) r.significand /= int(10**uint(expReducer));
        //     else r.significand *= int(10**uint(expReducer * -1));
            
        // }
    }

    function toPackedFloat(int mantissa,int exponent) internal pure returns (packedFloat float) {
        uint digitsMantissa;
        uint mantissaMultiplier;
        // we start by extracting the sign of the mantissa
        if(mantissa != 0){
            assembly {
                if and(mantissa, TOW_COMPLEMENT_SIGN_MASK) {
                    float := MANTISSA_SIGN_MASK
                    mantissa := sub(0,mantissa)
                }
            }
            // we normalize only if necessary
            if(uint(mantissa) > MAX_38_DIGIT_NUMBER || uint(mantissa) < MIN_38_DIGIT_NUMBER){
                digitsMantissa = findNumberOfDigits(uint(mantissa));
                assembly{
                    mantissaMultiplier := sub(digitsMantissa, MAX_DIGITS)
                    exponent := add(exponent, mantissaMultiplier)
                    let negativeMultiplier := and(TOW_COMPLEMENT_SIGN_MASK, mantissaMultiplier)
                    if negativeMultiplier{
                        mantissa := mul(mantissa,exp(BASE, sub(0, mantissaMultiplier)))
                    }
                    if iszero(negativeMultiplier){
                        mantissa := div(mantissa,exp(BASE, mantissaMultiplier))
                    }
                }
            }
            // final encoding
            assembly{
                float := or(float, or(mantissa, shl(EXPONENT_BIT, add(exponent, ZERO_OFFSET))))
            }
        }
    }

    function decode(
        packedFloat float
    ) internal pure returns (int mantissa, int exponent) {
        assembly {
            // exponent
            let _exp := shr(EXPONENT_BIT, float)
            if gt(ZERO_OFFSET, _exp) {
                exponent := sub(0,sub(ZERO_OFFSET, _exp))
            }
            if gt(_exp, ZERO_OFFSET_MINUS_1) {
                exponent := sub(_exp, ZERO_OFFSET)
            }
            // mantissa
            mantissa := and(float, MANTISSA_MASK)
            /// we use complements 2 for mantissa sign
            if and(float, MANTISSA_SIGN_MASK) {
                mantissa := sub(0,mantissa)
            }
        }
    }

    function normalize(Float memory x) internal pure returns(Float memory float){
        uint digitsMantissa;
        uint mantissaMultiplier;
        bool isMantissaNegative;

        if(x.significand == 0){
            float.exponent = -128;
            float.significand = 0;
        }
        else {
            assembly{
                isMantissaNegative := and(mload(x), MANTISSA_SIGN_MASK)
                if isMantissaNegative{
                    mstore(x, sub(0, mload(x)))
                }
            }
            if(uint(x.significand) > MAX_38_DIGIT_NUMBER || uint(x.significand) < MIN_38_DIGIT_NUMBER){
                digitsMantissa = findNumberOfDigits(uint(x.significand));
                assembly{
                    mantissaMultiplier := sub(digitsMantissa, MAX_DIGITS)
                    mstore(add(x, 0x20), add(mload(add(x, 0x20)), mantissaMultiplier))
                    let negativeMultiplier := and(MANTISSA_SIGN_MASK, mantissaMultiplier)
                    if negativeMultiplier{
                        mstore(x, mul(mload(x),exp(BASE, sub(0, mantissaMultiplier))))
                    }
                    if iszero(negativeMultiplier){
                        mstore(x, div(mload(x),exp(BASE, mantissaMultiplier)))
                    }
                }
            }
            assembly{
                if isMantissaNegative{
                    mstore(x, sub(0, mload(x)))
                }
            }
            float = x;
        }
    }

    function toFloat(int _significand, int _exponent) internal pure returns(Float memory float){
        float = normalize(Float({significand: _significand, exponent: _exponent}));
    }

    function convertToPackedFloat(Float memory _float) internal pure returns(packedFloat float){
        float = toPackedFloat(_float.significand, _float.exponent);
    }

    function convertToUnpackedFloat(packedFloat _float) internal pure returns(Float memory float){
        (float.significand, float.exponent) = decode(_float);
    }

    function findNumberOfDigits(uint x) internal pure returns (uint log) {
        assembly {
            if gt(x, 0) {
                if gt(
                    x,
                    9999999999999999999999999999999999999999999999999999999999999999
                ) {
                    log := 64
                    x := div(
                        x,
                        10000000000000000000000000000000000000000000000000000000000000000
                    )
                }
                if gt(x, 99999999999999999999999999999999) {
                    log := add(log, 32)
                    x := div(x, 100000000000000000000000000000000)
                }
                if gt(x, 9999999999999999) {
                    log := add(log, 16)
                    x := div(x, 10000000000000000)
                }
                if gt(x, 99999999) {
                    log := add(log, 8)
                    x := div(x, 100000000)
                }
                if gt(x, 9999) {
                    log := add(log, 4)
                    x := div(x, 10000)
                }
                if gt(x, 99) {
                    log := add(log, 2)
                    x := div(x, 100)
                }
                if gt(x, 9) {
                    log := add(log, 1)
                }
                log := add(log, 1)
            }
        }
    }
}