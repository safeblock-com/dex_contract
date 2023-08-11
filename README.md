# Multiswap router

### Smart contract that allows multiswaps in a path of pairs in V2 and V3  versions of uniswap logic

## Multiswap

The method takes the following calldata:
```solidity
struct MultiswapCalldata {
    // initial exact value in
    uint256 amountIn;
    // minimal amountOut
    uint256 minAmountOut;
    // first token in swap
    address tokenIn;
    // array of bytes32 values (pairs) involved in the swap
    // from left to right:
    //     address of the pair - 20 bytes
    //     fee in pair - 3 bytes (for V2 pairs)
    //     the highest bit shows which version the pair belongs to
    // example:
    //     V3: 0x8000000000000000000000004f31Fa980a675570939B737Ebdde0471a4Be40Eb
    //     V2: 0x00000000000000000000001e65E9CfDBC579856B6354d369AFBFbA2B2a3C7856
    bytes32[] pairs;
    // an optional address that slightly relaxes the protocol's fees in favor of that address 
    // and the user who called the multiswap
    address refferalAddress;
}
``` 

Note: depending on the number of pairs and tokens gas cost varies between 100k and 300k (up to 4 pairs on the route)

Example call:

```solidity
    MultiswapRouter.MultiswapCalldata memory data;
    data.amountIn = 1e18;
    data.tokenIn = WBNB;
    data.pairs = new bytes32[](3);
    // WBNB -> BUSD -> USDT -> CAKE
    data.pairs[0] = WBNB_BUSD_Cake;
    data.pairs[1] = BUSD_USDT_CakeV3_500;
    data.pairs[2] = USDT_USDC_CakeV3_500;
    data.refferalAddress = address(0);
    data.minAmountOut = 200e18; // 200 Cakes

    multiswapRouter.multiswap(data);
```

## Fees

There are 2 types of commission charges in the protocol:

Regular protocol fee:
    `exactOutputAmount = amountOut * protocolFee / 10000`

Commission using a referral address (if `refferalAddress` in calldata != address(0)):
```solidity
    example
    protocolPart = 200 bps
    refferalPart = 50 bps
    refferalFee = amountOut * refferalPart / 10000
    protocolFee = amountOut * protocolPart / 10000
    exactOutputAmount = amountOut - refferalFee - protocolFee
```

Protocol fees are saved in mapping:
    `profit(address(this), tokenAddress)`

Fees for referral addresses are also saved in the mapping:
    `profit(refferalAddress, tokenAddress)`

The referral address can at any time withdraw assets that are registered to its address:
```solidity
    multiswapRouter.collectRefferalFees(tokenAddress, recipient, amountForWithdraw)
    or withdraw all:
    multiswapRouter.collectRefferalFees(tokenAddress, recipient)
```

The protocol commission can be withdrawn only by the MultiswapRouter contract owner:
```solidity
    multiswapRouter.collectProtocolFees(tokenAddress, recipient, amountForWithdraw)
    or withdraw all:
    multiswapRouter.collectProtocolFees(tokenAddress, recipient)
```