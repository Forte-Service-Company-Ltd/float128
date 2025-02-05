import argparse
from decimal import *
from eth_abi import encode


def calculate_float_div(args):

    aMan = Decimal(args.aMan)
    aExp = Decimal(args.aExp)
    bMan = Decimal(args.bMan)
    bExp = Decimal(args.bExp)

    a = Decimal(aMan * 10**aExp)
    b = Decimal(bMan * 10**bExp)

    isNegative = False
    result = a / b
    if result < 0:
        isNegative = True
        result = abs(result)

    return result




def parse_args():
    parser = argparse.ArgumentParser()
    parser.add_argument("aMan", type=int)
    parser.add_argument("aExp", type=int)
    parser.add_argument("bMan", type=int)
    parser.add_argument("bExp", type=int)
    return parser.parse_args()


def main():
    args = parse_args()
    result = calculate_float_div(args)
    enc = encode(["int256"], [int(result)])
    print("0x" + enc.hex(), end="")


if __name__ == "__main__":
    main()