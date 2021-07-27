// SPDX-License-Identifier: MIT

pragma solidity >=0.6.6;
pragma experimental ABIEncoderV2;

// Copyright (c) 2021 SoulSwap
// Twitter: @SoulSwapFinance

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function owner() external view returns (address);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface ISoulSummoner {
    function bonusMultiplier() external view returns (uint256);
    function migrator() external view returns (address);
    function owner() external view returns (address);
    function startTime() external view returns (uint256);
    function soul() external view returns (address);
    function soulPerSecond() external view returns (uint256);
    function totalAllocPoint() external view returns (uint256);
    function poolLength() external view returns (uint256);
    function poolInfo(uint256 pid) external view returns (
            address,
            uint256,
            uint256,
            uint256
        );

    function userInfo(uint256 pid, address user) external view returns (uint256, uint256);
    function pendingSoul(uint256 pid, address user) external view returns (uint256);
}

interface IPair is IERC20 {
    function token0() external view returns (IERC20);
    function token1() external view returns (IERC20);
    function getReserves() external view returns (uint112, uint112, uint32);
}

interface IFactory {
    function INIT_CODE_PAIR_HASH() external view returns (bytes32);
    function totalPairs() external view returns (uint256);
    function allPairs(uint256 i) external view returns (IPair);
    function getPair(IERC20 token0, IERC20 token1) external view returns (IPair);
    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);
}

library BoringMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
        require((c = a + b) >= b, "BoringMath: Add Overflow");
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256 c) {
        require((c = a - b) <= a, "BoringMath: Underflow");
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
        require(b == 0 || (c = a * b) / b == a, "BoringMath: Mul Overflow");
    }
}

contract Ownable {
    address public immutable owner;

    constructor() internal {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }
}

library BoringERC20 {
    function returnDataToString(bytes memory data) internal pure returns (string memory) {
        if (data.length >= 64) {
            return abi.decode(data, (string));
        } else if (data.length == 32) {
            uint8 i = 0;
            while (i < 32 && data[i] != 0) {
                i++;
            }
            bytes memory bytesArray = new bytes(i);
            for (i = 0; i < 32 && data[i] != 0; i++) {
                bytesArray[i] = data[i];
            }
            return string(bytesArray);
        } else {
            return "???";
        }
    }

    function symbol(IERC20 token) internal view returns (string memory) {
        (bool success, bytes memory data) = address(token).staticcall(abi.encodeWithSelector(0x95d89b41));
        return success ? returnDataToString(data) : "???";
    }

    function name(IERC20 token) internal view returns (string memory) {
        (bool success, bytes memory data) = address(token).staticcall(abi.encodeWithSelector(0x06fdde03));
        return success ? returnDataToString(data) : "???";
    }

    function decimals(IERC20 token) internal view returns (uint8) {
        (bool success, bytes memory data) = address(token).staticcall(abi.encodeWithSelector(0x313ce567));
        return success && data.length == 32 ? abi.decode(data, (uint8)) : 18;
    }

    function DOMAIN_SEPARATOR(IERC20 token) internal view returns (bytes32) {
        (bool success, bytes memory data) = address(token).staticcall{gas: 10000}(abi.encodeWithSelector(0x3644e515));
        return success && data.length == 32 ? abi.decode(data, (bytes32)) : bytes32(0);
    }

    function nonces(IERC20 token, address owner) internal view returns (uint256) {
        (bool success, bytes memory data) = address(token).staticcall{gas: 5000}(abi.encodeWithSelector(0x7ecebe00, owner));
        return success && data.length == 32 ? abi.decode(data, (uint256)) : uint256(-1); // Use max uint256 to signal failure to retrieve nonce (probably not supported)
    }
}

library BoringPair {
    function factory(IPair pair) internal view returns (IFactory) {
        (bool success, bytes memory data) = address(pair).staticcall(abi.encodeWithSelector(0xc45a0155));
        return success && data.length == 32 ? abi.decode(data, (IFactory)) : IFactory(0);
    }
}

interface IStrategy {
    function skim(uint256 amount) external;

    function harvest(uint256 balance, address sender) external returns (int256 amountAdded);

    function withdraw(uint256 amount) external returns (uint256 actualAmount);

    function exit(uint256 balance) external returns (int256 amountAdded);
}

interface ICoffinBox {
    event LogDeploy(address indexed masterContract, bytes data, address indexed cloneAddress);
    event LogDeposit(address indexed token, address indexed from, address indexed to, uint256 amount, uint256 share);
    event LogFlashLoan(address indexed borrower, address indexed token, uint256 amount, uint256 feeAmount, address indexed receiver);
    event LogRegisterProtocol(address indexed protocol);
    event LogSetMasterContractApproval(address indexed masterContract, address indexed user, bool approved);
    event LogStrategyDivest(address indexed token, uint256 amount);
    event LogStrategyInvest(address indexed token, uint256 amount);
    event LogStrategyLoss(address indexed token, uint256 amount);
    event LogStrategyProfit(address indexed token, uint256 amount);
    event LogStrategyQueued(address indexed token, address indexed strategy);
    event LogStrategySet(address indexed token, address indexed strategy);
    event LogStrategyTargetPercentage(address indexed token, uint256 targetPercentage);
    event LogTransfer(address indexed token, address indexed from, address indexed to, uint256 share);
    event LogWhiteListMasterContract(address indexed masterContract, bool approved);
    event LogWithdraw(address indexed token, address indexed from, address indexed to, uint256 amount, uint256 share);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    function balanceOf(IERC20, address) external view returns (uint256);

    function batch(bytes[] calldata calls, bool revertOnFail) external payable returns (bool[] memory successes, bytes[] memory results);

    function claimOwnership() external;

    function deploy(
        address masterContract,
        bytes calldata data,
        bool useCreate2
    ) external payable;

    function deposit(
        IERC20 token_,
        address from,
        address to,
        uint256 amount,
        uint256 share
    ) external payable returns (uint256 amountOut, uint256 shareOut);

    function harvest(
        IERC20 token,
        bool balance,
        uint256 maxChangeAmount
    ) external;

    function masterContractApproved(address, address) external view returns (bool);

    function masterContractOf(address) external view returns (address);

    function nonces(address) external view returns (uint256);

    function owner() external view returns (address);

    function pendingOwner() external view returns (address);

    function pendingStrategy(IERC20) external view returns (IStrategy);

    function permitToken(
        IERC20 token,
        address from,
        address to,
        uint256 amount,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    function registerProtocol() external;

    function setMasterContractApproval(
        address user,
        address masterContract,
        bool approved,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    function setStrategy(IERC20 token, IStrategy newStrategy) external;

    function setStrategyTargetPercentage(IERC20 token, uint64 targetPercentage_) external;

    function strategy(IERC20) external view returns (IStrategy);

    function strategyData(IERC20)
        external
        view
        returns (
            uint64 strategyStartDate,
            uint64 targetPercentage,
            uint128 balance
        );

    function toAmount(
        IERC20 token,
        uint256 share,
        bool roundUp
    ) external view returns (uint256 amount);

    function toShare(
        IERC20 token,
        uint256 amount,
        bool roundUp
    ) external view returns (uint256 share);

    function totals(IERC20) external view returns (uint128 elastic, uint128 base);

    function transfer(
        IERC20 token,
        address from,
        address to,
        uint256 share
    ) external;

    function transferMultiple(
        IERC20 token,
        address from,
        address[] calldata tos,
        uint256[] calldata shares
    ) external;

    function transferOwnership(
        address newOwner,
        bool direct,
        bool renounce
    ) external;

    function whitelistMasterContract(address masterContract, bool approved) external;

    function whitelistedMasterContracts(address) external view returns (bool);

    function withdraw(
        IERC20 token_,
        address from,
        address to,
        uint256 amount,
        uint256 share
    ) external returns (uint256 amountOut, uint256 shareOut);
}

struct Rebase {
    uint128 elastic;
    uint128 base;
}

struct AccrueInfo {
    uint64 interestPerSecond;
    uint64 lastAccrued;
    uint128 feesEarnedFraction;
}

interface IOracle {
    function get(bytes calldata data) external returns (bool success, uint256 rate);

    function peek(bytes calldata data) external view returns (bool success, uint256 rate);

    function peekSpot(bytes calldata data) external view returns (uint256 rate);

    function symbol(bytes calldata data) external view returns (string memory);

    function name(bytes calldata data) external view returns (string memory);
}

interface IUnderworldPair {
    function DOMAIN_SEPARATOR() external view returns (bytes32);

    function accrue() external;

    function accrueInfo() external view returns (AccrueInfo memory info);

    function addAsset(
        address to,
        bool skim,
        uint256 share
    ) external returns (uint256 fraction);

    function addCollateral(
        address to,
        bool skim,
        uint256 share
    ) external;

    function allowance(address, address) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function asset() external view returns (IERC20);

    function balanceOf(address) external view returns (uint256);

    function coffinBox() external view returns (ICoffinBox);

    function borrow(address to, uint256 amount) external returns (uint256 part, uint256 share);

    function claimOwnership() external;

    function collateral() external view returns (IERC20);

    function cook(
        uint8[] calldata actions,
        uint256[] calldata values,
        bytes[] calldata datas
    ) external payable returns (uint256 value1, uint256 value2);

    function decimals() external view returns (uint8);

    function exchangeRate() external view returns (uint256);

    function feeTo() external view returns (address);

    function getInitData(
        IERC20 collateral_,
        IERC20 asset_,
        address oracle_,
        bytes calldata oracleData_
    ) external pure returns (bytes memory data);

    function init(bytes calldata data) external payable;

    function isSolvent(address user, bool open) external view returns (bool);

    function liquidate(
        address[] calldata users,
        uint256[] calldata borrowParts,
        address to,
        address swapper,
        bool open
    ) external;

    function masterContract() external view returns (address);

    function name() external view returns (string memory);

    function nonces(address) external view returns (uint256);

    function oracle() external view returns (IOracle);

    function oracleData() external view returns (bytes memory);

    function owner() external view returns (address);

    function pendingOwner() external view returns (address);

    function permit(
        address owner_,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    function removeAsset(address to, uint256 fraction) external returns (uint256 share);

    function removeCollateral(address to, uint256 share) external;

    function repay(
        address to,
        bool skim,
        uint256 part
    ) external returns (uint256 amount);

    function setFeeTo(address newFeeTo) external;

    function setSwapper(address swapper, bool enable) external;

    function swappers(address) external view returns (bool);

    function symbol() external view returns (string memory);

    function totalAsset() external view returns (Rebase memory total);

    function totalBorrow() external view returns (Rebase memory total);

    function totalCollateralShare() external view returns (uint256);

    function totalSupply() external view returns (uint256);

    function transfer(address to, uint256 amount) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);

    function transferOwnership(
        address newOwner,
        bool direct,
        bool renounce
    ) external;

    function updateExchangeRate() external returns (bool updated, uint256 rate);

    function userBorrowPart(address) external view returns (uint256);

    function userCollateralShare(address) external view returns (uint256);

    function withdrawFees() external;
}


contract SoulGuide is Ownable {
    using BoringMath for uint256;
    using BoringERC20 for IERC20;
    using BoringERC20 for IPair;
    using BoringPair for IPair;

    ISoulSummoner public summoner; // ISummoner(0x5cED956c0d3dC88B8C3E42494F7b2e052d7CfeBc);
    address public maker; // ISoulMaker();
    IERC20 public soul; // ISoulToken(0xfF84964E7A446466669da84be6c72Fe10eA786cF);
    IERC20 public WETH; // 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    IERC20 public WBTC; // 0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599;
    IFactory public soulFactory; // IFactory();
    IFactory public uniV2Factory; // IFactory();
    IERC20 public spell; // 0xb5083b964a0B6A447564657285AeE1E76524B3Db
    ICoffinBox public coffinBox; //

    function initialize (
        ISoulSummoner summoner_,
        address maker_,
        IERC20 soul_,
        IERC20 WETH_,
        IERC20 WBTC_,
        IFactory soulFactory_,
        IFactory uniV2Factory_,
        IERC20 spell_,
        ICoffinBox coffinBox_
    ) external onlyOwner {
        summoner = summoner_;
        maker = maker_;
        soul = soul_;
        WETH = WETH_;
        WBTC = WBTC_;
        soulFactory = soulFactory_;
        uniV2Factory = uniV2Factory_;
        spell = spell_;
        coffinBox = coffinBox_;
    }

    function setContracts(
        ISoulSummoner summoner_,
        address maker_,
        IERC20 soul_,
        IERC20 WETH_,
        IERC20 WBTC_,
        IFactory soulFactory_,
        IFactory uniV2Factory_,
        IERC20 spell_,
        ICoffinBox coffinBox_
    ) public onlyOwner {
        summoner = summoner_;
        maker = maker_;
        soul = soul_;
        WETH = WETH_;
        WBTC = WBTC_;
        soulFactory = soulFactory_;
        uniV2Factory = uniV2Factory_;
        spell = spell_;
        coffinBox = coffinBox_;
    }

    function getETHRate(IERC20 token) public view returns (uint256) {
        if (token == WETH) {
            return 1e18;
        }
        IPair pairUniV2;
        IPair pairSoul;
        if (uniV2Factory != IFactory(0)) {
            pairUniV2 = IPair(uniV2Factory.getPair(token, WETH));
        }
        if (soulFactory != IFactory(0)) {
            pairSoul = IPair(soulFactory.getPair(token, WETH));
        }
        if (address(pairUniV2) == address(0) && address(pairSoul) == address(0)) {
            return 0;
        }

        uint112 reserve0;
        uint112 reserve1;
        IERC20 token0;
        if (address(pairUniV2) != address(0)) {
            (uint112 reserve0UniV2, uint112 reserve1UniV2, ) = pairUniV2.getReserves();
            reserve0 += reserve0UniV2;
            reserve1 += reserve1UniV2;
            token0 = pairUniV2.token0();
        }

        if (address(pairSoul) != address(0)) {
            (uint112 reserve0Soul, uint112 reserve1Soul, ) = pairSoul.getReserves();
            reserve0 += reserve0Soul;
            reserve1 += reserve1Soul;
            if (token0 == IERC20(0)) {
                token0 = pairSoul.token0();
            }
        }

        if (token0 == WETH) {
            return (uint256(reserve1) * 1e18) / reserve0;
        } else {
            return (uint256(reserve0) * 1e18) / reserve1;
        }
    }

    struct Factory {
        bytes32 INIT_CODE_PAIR_HASH;
        IFactory factory;
        uint256 totalPairs;
    }

    struct Factories {
        bytes32 INIT_CODE_PAIR_HASH;
        Factory[] factories;
        uint256 totalPairs;
    }

    function getPairHash(IFactory[] calldata factoryAddresses) external view returns (bytes32) {
        Factories memory data;
        data.factories = new Factory[](factoryAddresses.length);
        for (uint256 i = 0; i < factoryAddresses.length; i++) {
            IFactory factory = factoryAddresses[i];
            data.factories[i].factory = factory;
            data.factories[i].INIT_CODE_PAIR_HASH = factory.INIT_CODE_PAIR_HASH();
        }    
    }

    struct UIInfo {
        uint256 ethBalance;
        uint256 soulBalance;
        uint256 spellBoundBalance;
        uint256 spellBalance;
        uint256 spellSupply;
        uint256 spellBoundAllowance;
        Factory[] factories;
        uint256 ethRate;
        uint256 soulRate;
        uint256 btcRate;
        uint256 pendingSoul;
        uint256 blockTimeStamp;
        bool[] masterContractApproved;
    }

    function getUIInfo(
        address who,
        IFactory[] memory factoryAddresses,
        IERC20 currency,
        address[] memory masterContracts
    ) public view returns (UIInfo memory) {
        UIInfo memory info;
        info.ethBalance = who.balance;

        info.factories = new Factory[](factoryAddresses.length);
        for (uint256 i = 0; i < factoryAddresses.length; i++) {
            IFactory factory = factoryAddresses[i];
            info.factories[i].factory = factory;
            info.factories[i].totalPairs = factory.totalPairs();
        }

        info.masterContractApproved = new bool[](masterContracts.length);
        for (uint256 i = 0; i < masterContracts.length; i++) {
            info.masterContractApproved[i] = coffinBox.masterContractApproved(masterContracts[i], who);
        }

        if (currency != IERC20(0)) {
            info.ethRate = getETHRate(currency);
        }

        if (WBTC != IERC20(0)) {
            info.btcRate = getETHRate(WBTC);
        }

        if (soul != IERC20(0)) {
            info.soulRate = getETHRate(soul);
            info.soulBalance = soul.balanceOf(who);
            info.spellBoundBalance = soul.balanceOf(address(spell));
            info.spellBoundAllowance = soul.allowance(who, address(spell));
        }

        if (spell != IERC20(0)) {
            info.spellBalance = spell.balanceOf(who);
            info.spellSupply = spell.totalSupply();
        }

        if (summoner != ISoulSummoner(0)) {
            uint256 poolLength = summoner.poolLength();
            uint256 pendingSoul;
            for (uint256 i = 0; i < poolLength; i++) {
                pendingSoul += summoner.pendingSoul(i, who);
            }
            info.pendingSoul = pendingSoul;
        }
        info.blockTimeStamp = block.timestamp;

        return info;
    }

    struct Balance {
        IERC20 token;
        uint256 balance;
        uint256 coffinBalance;
    }

    struct BalanceFull {
        IERC20 token;
        uint256 totalSupply;
        uint256 balance;
        uint256 coffinBalance;
        uint256 coffinAllowance;
        uint256 nonce;
        uint128 coffinAmount;
        uint128 coffinShare;
        uint256 rate;
    }

    struct TokenInfo {
        IERC20 token;
        uint256 decimals;
        string name;
        string symbol;
        bytes32 DOMAIN_SEPARATOR;
    }

    function getTokenInfo(address[] memory addresses) public view returns (TokenInfo[] memory) {
        TokenInfo[] memory infos = new TokenInfo[](addresses.length);

        for (uint256 i = 0; i < addresses.length; i++) {
            IERC20 token = IERC20(addresses[i]);
            infos[i].token = token;

            infos[i].name = token.name();
            infos[i].symbol = token.symbol();
            infos[i].decimals = token.decimals();
            infos[i].DOMAIN_SEPARATOR = token.DOMAIN_SEPARATOR();
        }

        return infos;
    }

    function findBalances(address who, address[] memory addresses) public view returns (Balance[] memory) {
        Balance[] memory balances = new Balance[](addresses.length);

        uint256 len = addresses.length;
        for (uint256 i = 0; i < len; i++) {
            IERC20 token = IERC20(addresses[i]);
            balances[i].token = token;
            balances[i].balance = token.balanceOf(who);
            balances[i].coffinBalance = coffinBox.balanceOf(token, who);
        }

        return balances;
    }

    function getBalances(address who, IERC20[] memory addresses) public view returns (BalanceFull[] memory) {
        BalanceFull[] memory balances = new BalanceFull[](addresses.length);

        for (uint256 i = 0; i < addresses.length; i++) {
            IERC20 token = addresses[i];
            balances[i].totalSupply = token.totalSupply();
            balances[i].token = token;
            balances[i].balance = token.balanceOf(who);
            balances[i].coffinAllowance = token.allowance(who, address(coffinBox));
            balances[i].nonce = token.nonces(who);
            balances[i].coffinBalance = coffinBox.balanceOf(token, who);
            (balances[i].coffinAmount, balances[i].coffinShare) = coffinBox.totals(token);
            balances[i].rate = getETHRate(token);
        }

        return balances;
    }

    struct PairBase {
        IPair token;
        IERC20 token0;
        IERC20 token1;
        uint256 totalSupply;
    }

    function getPairs(
        IFactory factory,
        uint256 fromID,
        uint256 toID
    ) public view returns (PairBase[] memory) {
        PairBase[] memory pairs = new PairBase[](toID - fromID);

        for (uint256 id = fromID; id < toID; id++) {
            IPair token = factory.allPairs(id);
            uint256 i = id - fromID;
            pairs[i].token = token;
            pairs[i].token0 = token.token0();
            pairs[i].token1 = token.token1();
            pairs[i].totalSupply = token.totalSupply();
        }
        return pairs;
    }

    struct PairPoll {
        IPair token;
        uint256 reserve0;
        uint256 reserve1;
        uint256 totalSupply;
        uint256 balance;
    }

    function pollPairs(address who, IPair[] memory addresses) public view returns (PairPoll[] memory) {
        PairPoll[] memory pairs = new PairPoll[](addresses.length);
        for (uint256 i = 0; i < addresses.length; i++) {
            IPair token = addresses[i];
            pairs[i].token = token;
            (uint256 reserve0, uint256 reserve1, ) = token.getReserves();
            pairs[i].reserve0 = reserve0;
            pairs[i].reserve1 = reserve1;
            pairs[i].balance = token.balanceOf(who);
            pairs[i].totalSupply = token.totalSupply();
        }
        return pairs;
    }

    struct PoolsInfo {
        uint256 totalAllocPoint;
        uint256 poolLength;
    }

    struct PoolInfo {
        uint256 pid;
        IPair lpToken;
        uint256 allocPoint;
        bool isPair;
        IFactory factory;
        IERC20 token0;
        IERC20 token1;
        string name;
        string symbol;
        uint8 decimals;
    }

    function getPools(uint256[] memory pids) public view returns (PoolsInfo memory, PoolInfo[] memory) {
        PoolsInfo memory info;
        info.totalAllocPoint = summoner.totalAllocPoint();
        uint256 poolLength = summoner.poolLength();
        info.poolLength = poolLength;

        PoolInfo[] memory pools = new PoolInfo[](pids.length);

        for (uint256 i = 0; i < pids.length; i++) {
            pools[i].pid = pids[i];
            (address lpToken, uint256 allocPoint, , ) = summoner.poolInfo(pids[i]);
            IPair uniV2 = IPair(lpToken);
            pools[i].lpToken = uniV2;
            pools[i].allocPoint = allocPoint;

            pools[i].name = uniV2.name();
            pools[i].symbol = uniV2.symbol();
            pools[i].decimals = uniV2.decimals();

            pools[i].factory = uniV2.factory();
            if (pools[i].factory != IFactory(0)) {
                pools[i].isPair = true;
                pools[i].token0 = uniV2.token0();
                pools[i].token1 = uniV2.token1();
            }
        }
        return (info, pools);
    }

    struct PoolFound {
        uint256 pid;
        uint256 balance;
    }

    function findPools(address who, uint256[] memory pids) public view returns (PoolFound[] memory) {
        PoolFound[] memory pools = new PoolFound[](pids.length);

        for (uint256 i = 0; i < pids.length; i++) {
            pools[i].pid = pids[i];
            (pools[i].balance, ) = summoner.userInfo(pids[i], who);
        }

        return pools;
    }

    struct UserPoolInfo {
        uint256 pid;
        uint256 balance; // Balance of pool tokens
        uint256 totalSupply; // Token staked lp tokens
        uint256 lpBalance; // Balance of lp tokens not staked
        uint256 lpTotalSupply; // TotalSupply of lp tokens
        uint256 lpAllowance; // LP tokens approved for mastersummoner
        uint256 reserve0;
        uint256 reserve1;
        uint256 rewardDebt;
        uint256 pending; // Pending SOUL
    }

    function pollPools(address who, uint256[] memory pids) public view returns (UserPoolInfo[] memory) {
        UserPoolInfo[] memory pools = new UserPoolInfo[](pids.length);

        for (uint256 i = 0; i < pids.length; i++) {
            (uint256 amount, ) = summoner.userInfo(pids[i], who);
            pools[i].balance = amount;
            pools[i].pending = summoner.pendingSoul(pids[i], who);

            (address lpToken, , , ) = summoner.poolInfo(pids[i]);
            pools[i].pid = pids[i];
            IPair uniV2 = IPair(lpToken);
            IFactory factory = uniV2.factory();
            if (factory != IFactory(0)) {
                pools[i].totalSupply = uniV2.balanceOf(address(summoner));
                pools[i].lpAllowance = uniV2.allowance(who, address(summoner));
                pools[i].lpBalance = uniV2.balanceOf(who);
                pools[i].lpTotalSupply = uniV2.totalSupply();

                (uint112 reserve0, uint112 reserve1, ) = uniV2.getReserves();
                pools[i].reserve0 = reserve0;
                pools[i].reserve1 = reserve1;
            }
        }
        return pools;
    }

    struct UnderworldPairPoll {
        IERC20 collateral;
        IERC20 asset;
        IOracle oracle;
        bytes oracleData;
        uint256 totalCollateralShare;
        uint256 userCollateralShare;
        Rebase totalAsset;
        uint256 userAssetFraction;
        Rebase totalBorrow;
        uint256 userBorrowPart;
        uint256 currentExchangeRate;
        uint256 spotExchangeRate;
        uint256 oracleExchangeRate;
        AccrueInfo accrueInfo;
    }

    function pollUnderworldPairs(address who, IUnderworldPair[] memory pairsIn) public view returns (UnderworldPairPoll[] memory) {
        uint256 len = pairsIn.length;
        UnderworldPairPoll[] memory pairs = new UnderworldPairPoll[](len);

        for (uint256 i = 0; i < len; i++) {
            IUnderworldPair pair = pairsIn[i];
            pairs[i].collateral = pair.collateral();
            pairs[i].asset = pair.asset();
            pairs[i].oracle = pair.oracle();
            pairs[i].oracleData = pair.oracleData();
            pairs[i].totalCollateralShare = pair.totalCollateralShare();
            pairs[i].userCollateralShare = pair.userCollateralShare(who);
            pairs[i].totalAsset = pair.totalAsset();
            pairs[i].userAssetFraction = pair.balanceOf(who);
            pairs[i].totalBorrow = pair.totalBorrow();
            pairs[i].userBorrowPart = pair.userBorrowPart(who);

            pairs[i].currentExchangeRate = pair.exchangeRate();
            (, pairs[i].oracleExchangeRate) = pair.oracle().peek(pair.oracleData());
            pairs[i].spotExchangeRate = pair.oracle().peekSpot(pair.oracleData());
            pairs[i].accrueInfo = pair.accrueInfo();
        }

        return pairs;
    }
}