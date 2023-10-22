// Code generated - DO NOT EDIT.
// This file is a generated binding and any manual changes will be lost.

package contract

import (
	"errors"
	"math/big"
	"strings"

	ethereum "github.com/ethereum/go-ethereum"
	"github.com/ethereum/go-ethereum/accounts/abi"
	"github.com/ethereum/go-ethereum/accounts/abi/bind"
	"github.com/ethereum/go-ethereum/common"
	"github.com/ethereum/go-ethereum/core/types"
	"github.com/ethereum/go-ethereum/event"
)

// Reference imports to suppress errors if they are not otherwise used.
var (
	_ = errors.New
	_ = big.NewInt
	_ = strings.NewReader
	_ = ethereum.NotFound
	_ = bind.Bind
	_ = common.Big1
	_ = types.BloomLookup
	_ = event.NewSubscription
	_ = abi.ConvertType
)

// MultiswapRouterMultiswapCalldata is an auto generated low-level Go binding around an user-defined struct.
type MultiswapRouterMultiswapCalldata struct {
	AmountIn        *big.Int
	MinAmountOut    *big.Int
	TokenIn         common.Address
	Pairs           [][32]byte
	RefferalAddress common.Address
}

// MultiswapRouterPartswapCalldata is an auto generated low-level Go binding around an user-defined struct.
type MultiswapRouterPartswapCalldata struct {
	FullAmount      *big.Int
	MinAmountOut    *big.Int
	TokenIn         common.Address
	TokenOut        common.Address
	AmountsIn       []*big.Int
	Pairs           [][32]byte
	RefferalAddress common.Address
}

// MultiswapRouterRefferalFee is an auto generated low-level Go binding around an user-defined struct.
type MultiswapRouterRefferalFee struct {
	ProtocolPart *big.Int
	RefferalPart *big.Int
}

// ContractMetaData contains all meta data concerning the Contract contract.
var ContractMetaData = &bind.MetaData{
	ABI: "[{\"inputs\":[{\"internalType\":\"uint256\",\"name\":\"protocolFee_\",\"type\":\"uint256\"},{\"components\":[{\"internalType\":\"uint256\",\"name\":\"protocolPart\",\"type\":\"uint256\"},{\"internalType\":\"uint256\",\"name\":\"refferalPart\",\"type\":\"uint256\"}],\"internalType\":\"structMultiswapRouter.RefferalFee\",\"name\":\"refferalFee_\",\"type\":\"tuple\"}],\"stateMutability\":\"nonpayable\",\"type\":\"constructor\"},{\"inputs\":[],\"name\":\"MultiswapRouter_FailedV2Swap\",\"type\":\"error\"},{\"inputs\":[],\"name\":\"MultiswapRouter_FailedV3Swap\",\"type\":\"error\"},{\"inputs\":[],\"name\":\"MultiswapRouter_InvalidFeeValue\",\"type\":\"error\"},{\"inputs\":[],\"name\":\"MultiswapRouter_InvalidIntCast\",\"type\":\"error\"},{\"inputs\":[],\"name\":\"MultiswapRouter_InvalidOutAmount\",\"type\":\"error\"},{\"inputs\":[],\"name\":\"MultiswapRouter_InvalidPairsArray\",\"type\":\"error\"},{\"inputs\":[],\"name\":\"MultiswapRouter_InvalidPartswapCalldata\",\"type\":\"error\"},{\"inputs\":[],\"name\":\"MultiswapRouter_NewOwnerIsZeroAddress\",\"type\":\"error\"},{\"inputs\":[],\"name\":\"MultiswapRouter_SenderIsNotOwner\",\"type\":\"error\"},{\"inputs\":[],\"name\":\"MultiswapRouter_SenderMustBeUniswapV3Pool\",\"type\":\"error\"},{\"inputs\":[],\"name\":\"UniswapV2_InsufficientInputAmount\",\"type\":\"error\"},{\"inputs\":[],\"name\":\"UniswapV2_InsufficientLiquidity\",\"type\":\"error\"},{\"anonymous\":false,\"inputs\":[{\"indexed\":true,\"internalType\":\"address\",\"name\":\"previousOwner\",\"type\":\"address\"},{\"indexed\":true,\"internalType\":\"address\",\"name\":\"newOwner\",\"type\":\"address\"}],\"name\":\"OwnershipTransferred\",\"type\":\"event\"},{\"stateMutability\":\"nonpayable\",\"type\":\"fallback\"},{\"inputs\":[{\"internalType\":\"uint256\",\"name\":\"newProtocolFee\",\"type\":\"uint256\"}],\"name\":\"changeProtocolFee\",\"outputs\":[],\"stateMutability\":\"nonpayable\",\"type\":\"function\"},{\"inputs\":[{\"components\":[{\"internalType\":\"uint256\",\"name\":\"protocolPart\",\"type\":\"uint256\"},{\"internalType\":\"uint256\",\"name\":\"refferalPart\",\"type\":\"uint256\"}],\"internalType\":\"structMultiswapRouter.RefferalFee\",\"name\":\"newRefferalFee\",\"type\":\"tuple\"}],\"name\":\"changeRefferalFee\",\"outputs\":[],\"stateMutability\":\"nonpayable\",\"type\":\"function\"},{\"inputs\":[{\"internalType\":\"address\",\"name\":\"token\",\"type\":\"address\"},{\"internalType\":\"address\",\"name\":\"recipient\",\"type\":\"address\"}],\"name\":\"collectProtocolFees\",\"outputs\":[],\"stateMutability\":\"nonpayable\",\"type\":\"function\"},{\"inputs\":[{\"internalType\":\"address\",\"name\":\"token\",\"type\":\"address\"},{\"internalType\":\"address\",\"name\":\"recipient\",\"type\":\"address\"},{\"internalType\":\"uint256\",\"name\":\"amount\",\"type\":\"uint256\"}],\"name\":\"collectProtocolFees\",\"outputs\":[],\"stateMutability\":\"nonpayable\",\"type\":\"function\"},{\"inputs\":[{\"internalType\":\"address\",\"name\":\"token\",\"type\":\"address\"},{\"internalType\":\"address\",\"name\":\"recipient\",\"type\":\"address\"},{\"internalType\":\"uint256\",\"name\":\"amount\",\"type\":\"uint256\"}],\"name\":\"collectRefferalFees\",\"outputs\":[],\"stateMutability\":\"nonpayable\",\"type\":\"function\"},{\"inputs\":[{\"internalType\":\"address\",\"name\":\"token\",\"type\":\"address\"},{\"internalType\":\"address\",\"name\":\"recipient\",\"type\":\"address\"}],\"name\":\"collectRefferalFees\",\"outputs\":[],\"stateMutability\":\"nonpayable\",\"type\":\"function\"},{\"inputs\":[],\"name\":\"fees\",\"outputs\":[{\"internalType\":\"uint256\",\"name\":\"protocolFee\",\"type\":\"uint256\"},{\"components\":[{\"internalType\":\"uint256\",\"name\":\"protocolPart\",\"type\":\"uint256\"},{\"internalType\":\"uint256\",\"name\":\"refferalPart\",\"type\":\"uint256\"}],\"internalType\":\"structMultiswapRouter.RefferalFee\",\"name\":\"refferalFee\",\"type\":\"tuple\"}],\"stateMutability\":\"view\",\"type\":\"function\"},{\"inputs\":[{\"components\":[{\"internalType\":\"uint256\",\"name\":\"amountIn\",\"type\":\"uint256\"},{\"internalType\":\"uint256\",\"name\":\"minAmountOut\",\"type\":\"uint256\"},{\"internalType\":\"address\",\"name\":\"tokenIn\",\"type\":\"address\"},{\"internalType\":\"bytes32[]\",\"name\":\"pairs\",\"type\":\"bytes32[]\"},{\"internalType\":\"address\",\"name\":\"refferalAddress\",\"type\":\"address\"}],\"internalType\":\"structMultiswapRouter.MultiswapCalldata\",\"name\":\"data\",\"type\":\"tuple\"}],\"name\":\"multiswap\",\"outputs\":[],\"stateMutability\":\"nonpayable\",\"type\":\"function\"},{\"inputs\":[],\"name\":\"owner\",\"outputs\":[{\"internalType\":\"address\",\"name\":\"\",\"type\":\"address\"}],\"stateMutability\":\"view\",\"type\":\"function\"},{\"inputs\":[{\"components\":[{\"internalType\":\"uint256\",\"name\":\"fullAmount\",\"type\":\"uint256\"},{\"internalType\":\"uint256\",\"name\":\"minAmountOut\",\"type\":\"uint256\"},{\"internalType\":\"address\",\"name\":\"tokenIn\",\"type\":\"address\"},{\"internalType\":\"address\",\"name\":\"tokenOut\",\"type\":\"address\"},{\"internalType\":\"uint256[]\",\"name\":\"amountsIn\",\"type\":\"uint256[]\"},{\"internalType\":\"bytes32[]\",\"name\":\"pairs\",\"type\":\"bytes32[]\"},{\"internalType\":\"address\",\"name\":\"refferalAddress\",\"type\":\"address\"}],\"internalType\":\"structMultiswapRouter.PartswapCalldata\",\"name\":\"data\",\"type\":\"tuple\"}],\"name\":\"partswap\",\"outputs\":[],\"stateMutability\":\"nonpayable\",\"type\":\"function\"},{\"inputs\":[{\"internalType\":\"address\",\"name\":\"owner\",\"type\":\"address\"},{\"internalType\":\"address\",\"name\":\"token\",\"type\":\"address\"}],\"name\":\"profit\",\"outputs\":[{\"internalType\":\"uint256\",\"name\":\"balance\",\"type\":\"uint256\"}],\"stateMutability\":\"view\",\"type\":\"function\"},{\"inputs\":[{\"internalType\":\"address\",\"name\":\"newOwner\",\"type\":\"address\"}],\"name\":\"transferOwnership\",\"outputs\":[],\"stateMutability\":\"nonpayable\",\"type\":\"function\"}]",
	Bin: "0x60a060405234801562000010575f80fd5b5060405162002dd538038062002dd583398181016040528101906200003691906200029a565b6127108211806200005a575081815f015182602001516200005891906200030c565b115b1562000092576040517f9c4f9a7f00000000000000000000000000000000000000000000000000000000815260040160405180910390fd5b816002819055505f815f015190505f826020015190505f828260801b179050806003819055505f30905080608081815250503360015f6101000a81548173ffffffffffffffffffffffffffffffffffffffff021916908373ffffffffffffffffffffffffffffffffffffffff1602179055503373ffffffffffffffffffffffffffffffffffffffff165f73ffffffffffffffffffffffffffffffffffffffff167f8be0079c531659141344cd1fd0a4f28419497f9722a3daafe3b4186f6b6457e060405160405180910390a350505050505062000346565b5f604051905090565b5f80fd5b5f819050919050565b6200018b8162000177565b811462000196575f80fd5b50565b5f81519050620001a98162000180565b92915050565b5f80fd5b5f601f19601f8301169050919050565b7f4e487b71000000000000000000000000000000000000000000000000000000005f52604160045260245ffd5b620001fb82620001b3565b810181811067ffffffffffffffff821117156200021d576200021c620001c3565b5b80604052505050565b5f620002316200016a565b90506200023f8282620001f0565b919050565b5f604082840312156200025c576200025b620001af565b5b62000268604062000226565b90505f620002798482850162000199565b5f8301525060206200028e8482850162000199565b60208301525092915050565b5f8060608385031215620002b357620002b262000173565b5b5f620002c28582860162000199565b9250506020620002d58582860162000244565b9150509250929050565b7f4e487b71000000000000000000000000000000000000000000000000000000005f52601160045260245ffd5b5f620003188262000177565b9150620003258362000177565b925082820190508082111562000340576200033f620002df565b5b92915050565b608051612a5a6200037b5f395f818161095401528181610a1301528181610a5e01528181610f6d0152610fed0152612a5a5ff3fe608060405234801561000f575f80fd5b50600436106100b6575f3560e01c80639af1d35a1161006f5780639af1d35a146102ae578063e4ba7e1b146102cd578063e8f599f2146102e9578063f2fde38b14610305578063fd69f7ad14610321578063fe6874751461033d576100b7565b806327e97abc146101f057806340a714ab146102205780634d05d8cb1461023c5780638161b874146102585780638a3c8e5f146102745780638da5cb5b14610290576100b7565b5b5f8054906101000a900473ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff163373ffffffffffffffffffffffffffffffffffffffff161461013b576040517fe3a44e8900000000000000000000000000000000000000000000000000000000815260040160405180910390fd5b5f805f6101000a81548173ffffffffffffffffffffffffffffffffffffffff021916908373ffffffffffffffffffffffffffffffffffffffff1602179055505f805f6004359250602435915060843590505f8314801561019a57505f82145b156101d1576040517fe2c34a0200000000000000000000000000000000000000000000000000000000815260040160405180910390fd5b5f8084136101df57826101e1565b835b90506101ee823383610359565b005b61020a60048036038101906102059190612167565b6103d0565b60405161021791906121bd565b60405180910390f35b61023a60048036038101906102359190612167565b6103f0565b005b61025660048036038101906102519190612200565b61058f565b005b610272600480360381019061026d9190612200565b6106a9565b005b61028e60048036038101906102899190612272565b610849565b005b610298610bd6565b6040516102a591906122c8565b60405180910390f35b6102b6610bfe565b6040516102c492919061231d565b60405180910390f35b6102e760048036038101906102e2919061241d565b610c49565b005b61030360048036038101906102fe9190612466565b610d42565b005b61031f600480360381019061031a91906124ad565b611156565b005b61033b60048036038101906103369190612167565b6112de565b005b610357600480360381019061035291906124d8565b6113f7565b005b5f6040517fa9059cbb00000000000000000000000000000000000000000000000000000000815273ffffffffffffffffffffffffffffffffffffffff8416600482015282602482015260205f6044835f895af13d15601f3d1160015f51141617169150816103c9573d5f803e3d5ffd5b5050505050565b6004602052815f5260405f20602052805f5260405f205f91509150505481565b60015f9054906101000a900473ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff163373ffffffffffffffffffffffffffffffffffffffff1614610476576040517f8a55377600000000000000000000000000000000000000000000000000000000815260040160405180910390fd5b5f60045f3073ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff1681526020019081526020015f205f8473ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff1681526020019081526020015f205490505f811061058a578060045f3073ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff1681526020019081526020015f205f8573ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff1681526020019081526020015f205f8282540392505081905550610589838383610359565b5b505050565b5f60045f3373ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff1681526020019081526020015f205f8573ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff1681526020019081526020015f205490508181106106a3578160045f3373ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff1681526020019081526020015f205f8673ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff1681526020019081526020015f205f82825403925050819055506106a2848484610359565b5b50505050565b60015f9054906101000a900473ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff163373ffffffffffffffffffffffffffffffffffffffff161461072f576040517f8a55377600000000000000000000000000000000000000000000000000000000815260040160405180910390fd5b5f60045f3073ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff1681526020019081526020015f205f8573ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff1681526020019081526020015f20549050818110610843578160045f3073ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff1681526020019081526020015f205f8673ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff1681526020019081526020015f205f8282540392505081905550610842848484610359565b5b50505050565b5f81806060019061085a919061250f565b905090505f6001820390505f820361089e576040517f5661819c00000000000000000000000000000000000000000000000000000000815260040160405180910390fd5b5f8380606001906108af919061250f565b5f8181106108c0576108bf612571565b5b9050602002013590505f8073ffffffffffffffffffffffffffffffffffffffff831691507f8000000000000000000000000000000000000000000000000000000000000000831690505f865f013590505f87604001602081019061092491906124ad565b905061093e8133856109365786610938565b305b856114c3565b5f805f805b8a811015610aa35789810361097a577f000000000000000000000000000000000000000000000000000000000000000091506109ad565b8b806060019061098a919061250f565b61099383611557565b8181106109a3576109a2612571565b5b9050602002013591505b7f8000000000000000000000000000000000000000000000000000000000000000891696507f8000000000000000000000000000000000000000000000000000000000000000821692508615610a4957610a388a82148a888887610a115786610a33565b7f00000000000000000000000000000000000000000000000000000000000000005b611563565b809650819750829850505050610a90565b610a838a82148a8786610a5c5785610a7e565b7f00000000000000000000000000000000000000000000000000000000000000005b6118e9565b8096508197508298505050505b819850610a9c81611557565b9050610943565b505f8473ffffffffffffffffffffffffffffffffffffffff166370a08231306040518263ffffffff1660e01b8152600401610ade91906122c8565b602060405180830381865afa158015610af9573d5f803e3d5ffd5b505050506040513d601f19601f82011682018060405250810190610b1d91906125b2565b905083811015610b59576040517fc11438f900000000000000000000000000000000000000000000000000000000815260040160405180910390fd5b5f84820390508c60200135811015610b9d576040517fc11438f900000000000000000000000000000000000000000000000000000000815260040160405180910390fd5b610bba818e6080016020810190610bb491906124ad565b88611d73565b9050610bc7863383610359565b50505050505050505050505050565b5f60015f9054906101000a900473ffffffffffffffffffffffffffffffffffffffff16905090565b5f610c076120e4565b60025491505f60035490505f80826fffffffffffffffffffffffffffffffff1691508260801c905081845f018181525050808460200181815250505050509091565b60015f9054906101000a900473ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff163373ffffffffffffffffffffffffffffffffffffffff1614610ccf576040517f8a55377600000000000000000000000000000000000000000000000000000000815260040160405180910390fd5b600254815f01518260200151610ce5919061260a565b1115610d1d576040517f9c4f9a7f00000000000000000000000000000000000000000000000000000000815260040160405180910390fd5b5f815f015190505f826020015190505f828260801b1790508060038190555050505050565b5f818060a00190610d53919061250f565b90509050818060800190610d67919061263d565b90508114610da1576040517f3f46e84200000000000000000000000000000000000000000000000000000000815260040160405180910390fd5b5f805b82811015610de857838060800190610dbc919061263d565b82818110610dcd57610dcc612571565b5b9050602002013582019150610de181611557565b9050610da4565b50825f0135811115610e26576040517f3f46e84200000000000000000000000000000000000000000000000000000000815260040160405180910390fd5b5f836040016020810190610e3a91906124ad565b90505f846060016020810190610e5091906124ad565b9050610e61823330885f01356114c3565b5f805f8373ffffffffffffffffffffffffffffffffffffffff166370a08231306040518263ffffffff1660e01b8152600401610e9d91906122c8565b602060405180830381865afa158015610eb8573d5f803e3d5ffd5b505050506040513d601f19601f82011682018060405250810190610edc91906125b2565b90505f5b8781101561102657888060a00190610ef8919061250f565b82818110610f0957610f08612571565b5b9050602002013593507f8000000000000000000000000000000000000000000000000000000000000000841692508215610f9957610f915f858b8060800190610f52919061263d565b85818110610f6357610f62612571565b5b90506020020135897f0000000000000000000000000000000000000000000000000000000000000000611563565b505050611016565b5f73ffffffffffffffffffffffffffffffffffffffff85169050610fe587828c8060800190610fc8919061263d565b86818110610fd957610fd8612571565b5b90506020020135610359565b6110115f86897f00000000000000000000000000000000000000000000000000000000000000006118e9565b505050505b61101f81611557565b9050610ee0565b505f8473ffffffffffffffffffffffffffffffffffffffff166370a08231306040518263ffffffff1660e01b815260040161106191906122c8565b602060405180830381865afa15801561107c573d5f803e3d5ffd5b505050506040513d601f19601f820116820180604052508101906110a091906125b2565b9050818110156110dc576040517fc11438f900000000000000000000000000000000000000000000000000000000815260040160405180910390fd5b5f82820390508960200135811015611120576040517fc11438f900000000000000000000000000000000000000000000000000000000815260040160405180910390fd5b61113d818b60c001602081019061113791906124ad565b88611d73565b905061114a863383610359565b50505050505050505050565b60015f9054906101000a900473ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff163373ffffffffffffffffffffffffffffffffffffffff16146111dc576040517f8a55377600000000000000000000000000000000000000000000000000000000815260040160405180910390fd5b5f73ffffffffffffffffffffffffffffffffffffffff168173ffffffffffffffffffffffffffffffffffffffff1603611241576040517fdb69783e00000000000000000000000000000000000000000000000000000000815260040160405180910390fd5b8060015f6101000a81548173ffffffffffffffffffffffffffffffffffffffff021916908373ffffffffffffffffffffffffffffffffffffffff1602179055508073ffffffffffffffffffffffffffffffffffffffff163373ffffffffffffffffffffffffffffffffffffffff167f8be0079c531659141344cd1fd0a4f28419497f9722a3daafe3b4186f6b6457e060405160405180910390a350565b5f60045f3373ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff1681526020019081526020015f205f8473ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff1681526020019081526020015f205490505f81106113f2578060045f3373ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff1681526020019081526020015f205f8573ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff1681526020019081526020015f205f82825403925050819055506113f1838383610359565b5b505050565b60015f9054906101000a900473ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff163373ffffffffffffffffffffffffffffffffffffffff161461147d576040517f8a55377600000000000000000000000000000000000000000000000000000000815260040160405180910390fd5b6127108111156114b9576040517f9c4f9a7f00000000000000000000000000000000000000000000000000000000815260040160405180910390fd5b8060028190555050565b5f6040517f23b872dd00000000000000000000000000000000000000000000000000000000815273ffffffffffffffffffffffffffffffffffffffff8516600482015273ffffffffffffffffffffffffffffffffffffffff8416602482015282604482015260205f6064835f8a5af13d15601f3d1160015f511416171691508161154f573d5f803e3d5ffd5b505050505050565b5f600182019050919050565b5f805f805f73ffffffffffffffffffffffffffffffffffffffff8916915073ffffffffffffffffffffffffffffffffffffffff861690508173ffffffffffffffffffffffffffffffffffffffff16630dfe16816040518163ffffffff1660e01b8152600401602060405180830381865afa1580156115e3573d5f803e3d5ffd5b505050506040513d601f19601f8201168201806040525081019061160791906126b3565b93508673ffffffffffffffffffffffffffffffffffffffff168473ffffffffffffffffffffffffffffffffffffffff16036116ac578173ffffffffffffffffffffffffffffffffffffffff1663d21220a76040518163ffffffff1660e01b8152600401602060405180830381865afa158015611685573d5f803e3d5ffd5b505050506040513d601f19601f820116820180604052508101906116a991906126b3565b93505b891561172d578373ffffffffffffffffffffffffffffffffffffffff166370a08231306040518263ffffffff1660e01b81526004016116eb91906122c8565b602060405180830381865afa158015611706573d5f803e3d5ffd5b505050506040513d601f19601f8201168201806040525081019061172a91906125b2565b92505b5f8473ffffffffffffffffffffffffffffffffffffffff168873ffffffffffffffffffffffffffffffffffffffff161090507f800000000000000000000000000000000000000000000000000000000000000089106117b8576040517f75e73fca00000000000000000000000000000000000000000000000000000000815260040160405180910390fd5b825f806101000a81548173ffffffffffffffffffffffffffffffffffffffff021916908373ffffffffffffffffffffffffffffffffffffffff1602179055505f808473ffffffffffffffffffffffffffffffffffffffff1663128acb0885858e876118375773fffd8963efd1fc6a506488495d951d5263988d2561183e565b6401000276a45b8f60405160200161184f91906122c8565b6040516020818303038152906040526040518663ffffffff1660e01b815260040161187e959493929190612799565b60408051808303815f875af1158015611899573d5f803e3d5ffd5b505050506040513d601f19601f820116820180604052508101906118bd919061281b565b91509150826118cc57816118ce565b805b6118d790612859565b97505050505050955095509592505050565b5f805f805f8073ffffffffffffffffffffffffffffffffffffffff891692508860a01c62ffffff16915073ffffffffffffffffffffffffffffffffffffffff871690505f8373ffffffffffffffffffffffffffffffffffffffff16630dfe16816040518163ffffffff1660e01b8152600401602060405180830381865afa158015611976573d5f803e3d5ffd5b505050506040513d601f19601f8201168201806040525081019061199a91906126b3565b90508073ffffffffffffffffffffffffffffffffffffffff168973ffffffffffffffffffffffffffffffffffffffff16146119d55780611a43565b8373ffffffffffffffffffffffffffffffffffffffff1663d21220a76040518163ffffffff1660e01b8152600401602060405180830381865afa158015611a1e573d5f803e3d5ffd5b505050506040513d601f19601f82011682018060405250810190611a4291906126b3565b5b95508a15611ac6578573ffffffffffffffffffffffffffffffffffffffff166370a08231306040518263ffffffff1660e01b8152600401611a8491906122c8565b602060405180830381865afa158015611a9f573d5f803e3d5ffd5b505050506040513d601f19601f82011682018060405250810190611ac391906125b2565b94505b5f805f8673ffffffffffffffffffffffffffffffffffffffff16630902f1ac6040518163ffffffff1660e01b8152600401606060405180830381865afa158015611b12573d5f803e3d5ffd5b505050506040513d601f19601f82011682018060405250810190611b3691906128d8565b50915091505f808573ffffffffffffffffffffffffffffffffffffffff168e73ffffffffffffffffffffffffffffffffffffffff1614611b77578284611b7a565b83835b91509150818e73ffffffffffffffffffffffffffffffffffffffff166370a082318b6040518263ffffffff1660e01b8152600401611bb891906122c8565b602060405180830381865afa158015611bd3573d5f803e3d5ffd5b505050506040513d601f19601f82011682018060405250810190611bf791906125b2565b039450611c068583838b611fc2565b9b50505050505f808373ffffffffffffffffffffffffffffffffffffffff168c73ffffffffffffffffffffffffffffffffffffffff1614611c4857895f611c4b565b5f8a5b91509150611cc38763022c0d9f84848960405180602001604052805f815250604051602401611c7d9493929190612928565b6040516020818303038152906040529060e01b6020820180517bffffffffffffffffffffffffffffffffffffffffffffffffffffffff8381831617835250505050612074565b611d6257611d2b87636d9a640a848489604051602401611ce593929190612972565b6040516020818303038152906040529060e01b6020820180517bffffffffffffffffffffffffffffffffffffffffffffffffffffffff8381831617835250505050612074565b611d61576040517f74d3d55500000000000000000000000000000000000000000000000000000000815260040160405180910390fd5b5b505050505050509450945094915050565b5f8073ffffffffffffffffffffffffffffffffffffffff168373ffffffffffffffffffffffffffffffffffffffff1603611e51575f612710600254860281611dbe57611dbd6129a7565b5b0490508060045f3073ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff1681526020019081526020015f205f8573ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff1681526020019081526020015f205f8282540192505081905550808503915050611fbb565b5f60035490505f80826fffffffffffffffffffffffffffffffff1691508260801c90505f61271082890281611e8957611e886129a7565b5b0490505f612710848a0281611ea157611ea06129a7565b5b0490508160045f8a73ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff1681526020019081526020015f205f8973ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff1681526020019081526020015f205f82825401925050819055508060045f3073ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff1681526020019081526020015f205f8973ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff1681526020019081526020015f205f828254019250508190555080828a0303955050505050505b9392505050565b5f808503611ffc576040517f4566b3d300000000000000000000000000000000000000000000000000000000815260040160405180910390fd5b5f84148061200957505f83145b15612040576040517f4bfdd70e00000000000000000000000000000000000000000000000000000000815260040160405180910390fd5b5f82860290505f84820290505f826127108802019050808281612066576120656129a7565b5b049350505050949350505050565b5f8273ffffffffffffffffffffffffffffffffffffffff168260405161209a9190612a0e565b5f604051808303815f865af19150503d805f81146120d3576040519150601f19603f3d011682016040523d82523d5f602084013e6120d8565b606091505b50508091505092915050565b60405180604001604052805f81526020015f81525090565b5f604051905090565b5f80fd5b5f80fd5b5f73ffffffffffffffffffffffffffffffffffffffff82169050919050565b5f6121368261210d565b9050919050565b6121468161212c565b8114612150575f80fd5b50565b5f813590506121618161213d565b92915050565b5f806040838503121561217d5761217c612105565b5b5f61218a85828601612153565b925050602061219b85828601612153565b9150509250929050565b5f819050919050565b6121b7816121a5565b82525050565b5f6020820190506121d05f8301846121ae565b92915050565b6121df816121a5565b81146121e9575f80fd5b50565b5f813590506121fa816121d6565b92915050565b5f805f6060848603121561221757612216612105565b5b5f61222486828701612153565b935050602061223586828701612153565b9250506040612246868287016121ec565b9150509250925092565b5f80fd5b5f60a0828403121561226957612268612250565b5b81905092915050565b5f6020828403121561228757612286612105565b5b5f82013567ffffffffffffffff8111156122a4576122a3612109565b5b6122b084828501612254565b91505092915050565b6122c28161212c565b82525050565b5f6020820190506122db5f8301846122b9565b92915050565b6122ea816121a5565b82525050565b604082015f8201516123045f8501826122e1565b50602082015161231760208501826122e1565b50505050565b5f6060820190506123305f8301856121ae565b61233d60208301846122f0565b9392505050565b5f80fd5b5f601f19601f8301169050919050565b7f4e487b71000000000000000000000000000000000000000000000000000000005f52604160045260245ffd5b61238e82612348565b810181811067ffffffffffffffff821117156123ad576123ac612358565b5b80604052505050565b5f6123bf6120fc565b90506123cb8282612385565b919050565b5f604082840312156123e5576123e4612344565b5b6123ef60406123b6565b90505f6123fe848285016121ec565b5f830152506020612411848285016121ec565b60208301525092915050565b5f6040828403121561243257612431612105565b5b5f61243f848285016123d0565b91505092915050565b5f60e0828403121561245d5761245c612250565b5b81905092915050565b5f6020828403121561247b5761247a612105565b5b5f82013567ffffffffffffffff81111561249857612497612109565b5b6124a484828501612448565b91505092915050565b5f602082840312156124c2576124c1612105565b5b5f6124cf84828501612153565b91505092915050565b5f602082840312156124ed576124ec612105565b5b5f6124fa848285016121ec565b91505092915050565b5f80fd5b5f80fd5b5f80fd5b5f808335600160200384360303811261252b5761252a612503565b5b80840192508235915067ffffffffffffffff82111561254d5761254c612507565b5b6020830192506020820236038313156125695761256861250b565b5b509250929050565b7f4e487b71000000000000000000000000000000000000000000000000000000005f52603260045260245ffd5b5f815190506125ac816121d6565b92915050565b5f602082840312156125c7576125c6612105565b5b5f6125d48482850161259e565b91505092915050565b7f4e487b71000000000000000000000000000000000000000000000000000000005f52601160045260245ffd5b5f612614826121a5565b915061261f836121a5565b9250828201905080821115612637576126366125dd565b5b92915050565b5f808335600160200384360303811261265957612658612503565b5b80840192508235915067ffffffffffffffff82111561267b5761267a612507565b5b6020830192506020820236038313156126975761269661250b565b5b509250929050565b5f815190506126ad8161213d565b92915050565b5f602082840312156126c8576126c7612105565b5b5f6126d58482850161269f565b91505092915050565b5f8115159050919050565b6126f2816126de565b82525050565b5f819050919050565b61270a816126f8565b82525050565b6127198161210d565b82525050565b5f81519050919050565b5f82825260208201905092915050565b5f5b8381101561275657808201518184015260208101905061273b565b5f8484015250505050565b5f61276b8261271f565b6127758185612729565b9350612785818560208601612739565b61278e81612348565b840191505092915050565b5f60a0820190506127ac5f8301886122b9565b6127b960208301876126e9565b6127c66040830186612701565b6127d36060830185612710565b81810360808301526127e58184612761565b90509695505050505050565b6127fa816126f8565b8114612804575f80fd5b50565b5f81519050612815816127f1565b92915050565b5f806040838503121561283157612830612105565b5b5f61283e85828601612807565b925050602061284f85828601612807565b9150509250929050565b5f612863826126f8565b91507f80000000000000000000000000000000000000000000000000000000000000008203612895576128946125dd565b5b815f039050919050565b5f63ffffffff82169050919050565b6128b78161289f565b81146128c1575f80fd5b50565b5f815190506128d2816128ae565b92915050565b5f805f606084860312156128ef576128ee612105565b5b5f6128fc8682870161259e565b935050602061290d8682870161259e565b925050604061291e868287016128c4565b9150509250925092565b5f60808201905061293b5f8301876121ae565b61294860208301866121ae565b61295560408301856122b9565b81810360608301526129678184612761565b905095945050505050565b5f6060820190506129855f8301866121ae565b61299260208301856121ae565b61299f60408301846122b9565b949350505050565b7f4e487b71000000000000000000000000000000000000000000000000000000005f52601260045260245ffd5b5f81905092915050565b5f6129e88261271f565b6129f281856129d4565b9350612a02818560208601612739565b80840191505092915050565b5f612a1982846129de565b91508190509291505056fea2646970667358221220615b000182f49835c18e039ef17b48026d64407298b58dac92f9d78c06e2162e64736f6c63430008150033",
}

// ContractABI is the input ABI used to generate the binding from.
// Deprecated: Use ContractMetaData.ABI instead.
var ContractABI = ContractMetaData.ABI

// ContractBin is the compiled bytecode used for deploying new contracts.
// Deprecated: Use ContractMetaData.Bin instead.
var ContractBin = ContractMetaData.Bin

// DeployContract deploys a new Ethereum contract, binding an instance of Contract to it.
func DeployContract(auth *bind.TransactOpts, backend bind.ContractBackend, protocolFee_ *big.Int, refferalFee_ MultiswapRouterRefferalFee) (common.Address, *types.Transaction, *Contract, error) {
	parsed, err := ContractMetaData.GetAbi()
	if err != nil {
		return common.Address{}, nil, nil, err
	}
	if parsed == nil {
		return common.Address{}, nil, nil, errors.New("GetABI returned nil")
	}

	address, tx, contract, err := bind.DeployContract(auth, *parsed, common.FromHex(ContractBin), backend, protocolFee_, refferalFee_)
	if err != nil {
		return common.Address{}, nil, nil, err
	}
	return address, tx, &Contract{ContractCaller: ContractCaller{contract: contract}, ContractTransactor: ContractTransactor{contract: contract}, ContractFilterer: ContractFilterer{contract: contract}}, nil
}

// Contract is an auto generated Go binding around an Ethereum contract.
type Contract struct {
	ContractCaller     // Read-only binding to the contract
	ContractTransactor // Write-only binding to the contract
	ContractFilterer   // Log filterer for contract events
}

// ContractCaller is an auto generated read-only Go binding around an Ethereum contract.
type ContractCaller struct {
	contract *bind.BoundContract // Generic contract wrapper for the low level calls
}

// ContractTransactor is an auto generated write-only Go binding around an Ethereum contract.
type ContractTransactor struct {
	contract *bind.BoundContract // Generic contract wrapper for the low level calls
}

// ContractFilterer is an auto generated log filtering Go binding around an Ethereum contract events.
type ContractFilterer struct {
	contract *bind.BoundContract // Generic contract wrapper for the low level calls
}

// ContractSession is an auto generated Go binding around an Ethereum contract,
// with pre-set call and transact options.
type ContractSession struct {
	Contract     *Contract         // Generic contract binding to set the session for
	CallOpts     bind.CallOpts     // Call options to use throughout this session
	TransactOpts bind.TransactOpts // Transaction auth options to use throughout this session
}

// ContractCallerSession is an auto generated read-only Go binding around an Ethereum contract,
// with pre-set call options.
type ContractCallerSession struct {
	Contract *ContractCaller // Generic contract caller binding to set the session for
	CallOpts bind.CallOpts   // Call options to use throughout this session
}

// ContractTransactorSession is an auto generated write-only Go binding around an Ethereum contract,
// with pre-set transact options.
type ContractTransactorSession struct {
	Contract     *ContractTransactor // Generic contract transactor binding to set the session for
	TransactOpts bind.TransactOpts   // Transaction auth options to use throughout this session
}

// ContractRaw is an auto generated low-level Go binding around an Ethereum contract.
type ContractRaw struct {
	Contract *Contract // Generic contract binding to access the raw methods on
}

// ContractCallerRaw is an auto generated low-level read-only Go binding around an Ethereum contract.
type ContractCallerRaw struct {
	Contract *ContractCaller // Generic read-only contract binding to access the raw methods on
}

// ContractTransactorRaw is an auto generated low-level write-only Go binding around an Ethereum contract.
type ContractTransactorRaw struct {
	Contract *ContractTransactor // Generic write-only contract binding to access the raw methods on
}

// NewContract creates a new instance of Contract, bound to a specific deployed contract.
func NewContract(address common.Address, backend bind.ContractBackend) (*Contract, error) {
	contract, err := bindContract(address, backend, backend, backend)
	if err != nil {
		return nil, err
	}
	return &Contract{ContractCaller: ContractCaller{contract: contract}, ContractTransactor: ContractTransactor{contract: contract}, ContractFilterer: ContractFilterer{contract: contract}}, nil
}

// NewContractCaller creates a new read-only instance of Contract, bound to a specific deployed contract.
func NewContractCaller(address common.Address, caller bind.ContractCaller) (*ContractCaller, error) {
	contract, err := bindContract(address, caller, nil, nil)
	if err != nil {
		return nil, err
	}
	return &ContractCaller{contract: contract}, nil
}

// NewContractTransactor creates a new write-only instance of Contract, bound to a specific deployed contract.
func NewContractTransactor(address common.Address, transactor bind.ContractTransactor) (*ContractTransactor, error) {
	contract, err := bindContract(address, nil, transactor, nil)
	if err != nil {
		return nil, err
	}
	return &ContractTransactor{contract: contract}, nil
}

// NewContractFilterer creates a new log filterer instance of Contract, bound to a specific deployed contract.
func NewContractFilterer(address common.Address, filterer bind.ContractFilterer) (*ContractFilterer, error) {
	contract, err := bindContract(address, nil, nil, filterer)
	if err != nil {
		return nil, err
	}
	return &ContractFilterer{contract: contract}, nil
}

// bindContract binds a generic wrapper to an already deployed contract.
func bindContract(address common.Address, caller bind.ContractCaller, transactor bind.ContractTransactor, filterer bind.ContractFilterer) (*bind.BoundContract, error) {
	parsed, err := ContractMetaData.GetAbi()
	if err != nil {
		return nil, err
	}
	return bind.NewBoundContract(address, *parsed, caller, transactor, filterer), nil
}

// Call invokes the (constant) contract method with params as input values and
// sets the output to result. The result type might be a single field for simple
// returns, a slice of interfaces for anonymous returns and a struct for named
// returns.
func (_Contract *ContractRaw) Call(opts *bind.CallOpts, result *[]interface{}, method string, params ...interface{}) error {
	return _Contract.Contract.ContractCaller.contract.Call(opts, result, method, params...)
}

// Transfer initiates a plain transaction to move funds to the contract, calling
// its default method if one is available.
func (_Contract *ContractRaw) Transfer(opts *bind.TransactOpts) (*types.Transaction, error) {
	return _Contract.Contract.ContractTransactor.contract.Transfer(opts)
}

// Transact invokes the (paid) contract method with params as input values.
func (_Contract *ContractRaw) Transact(opts *bind.TransactOpts, method string, params ...interface{}) (*types.Transaction, error) {
	return _Contract.Contract.ContractTransactor.contract.Transact(opts, method, params...)
}

// Call invokes the (constant) contract method with params as input values and
// sets the output to result. The result type might be a single field for simple
// returns, a slice of interfaces for anonymous returns and a struct for named
// returns.
func (_Contract *ContractCallerRaw) Call(opts *bind.CallOpts, result *[]interface{}, method string, params ...interface{}) error {
	return _Contract.Contract.contract.Call(opts, result, method, params...)
}

// Transfer initiates a plain transaction to move funds to the contract, calling
// its default method if one is available.
func (_Contract *ContractTransactorRaw) Transfer(opts *bind.TransactOpts) (*types.Transaction, error) {
	return _Contract.Contract.contract.Transfer(opts)
}

// Transact invokes the (paid) contract method with params as input values.
func (_Contract *ContractTransactorRaw) Transact(opts *bind.TransactOpts, method string, params ...interface{}) (*types.Transaction, error) {
	return _Contract.Contract.contract.Transact(opts, method, params...)
}

// Fees is a free data retrieval call binding the contract method 0x9af1d35a.
//
// Solidity: function fees() view returns(uint256 protocolFee, (uint256,uint256) refferalFee)
func (_Contract *ContractCaller) Fees(opts *bind.CallOpts) (struct {
	ProtocolFee *big.Int
	RefferalFee MultiswapRouterRefferalFee
}, error) {
	var out []interface{}
	err := _Contract.contract.Call(opts, &out, "fees")

	outstruct := new(struct {
		ProtocolFee *big.Int
		RefferalFee MultiswapRouterRefferalFee
	})
	if err != nil {
		return *outstruct, err
	}

	outstruct.ProtocolFee = *abi.ConvertType(out[0], new(*big.Int)).(**big.Int)
	outstruct.RefferalFee = *abi.ConvertType(out[1], new(MultiswapRouterRefferalFee)).(*MultiswapRouterRefferalFee)

	return *outstruct, err

}

// Fees is a free data retrieval call binding the contract method 0x9af1d35a.
//
// Solidity: function fees() view returns(uint256 protocolFee, (uint256,uint256) refferalFee)
func (_Contract *ContractSession) Fees() (struct {
	ProtocolFee *big.Int
	RefferalFee MultiswapRouterRefferalFee
}, error) {
	return _Contract.Contract.Fees(&_Contract.CallOpts)
}

// Fees is a free data retrieval call binding the contract method 0x9af1d35a.
//
// Solidity: function fees() view returns(uint256 protocolFee, (uint256,uint256) refferalFee)
func (_Contract *ContractCallerSession) Fees() (struct {
	ProtocolFee *big.Int
	RefferalFee MultiswapRouterRefferalFee
}, error) {
	return _Contract.Contract.Fees(&_Contract.CallOpts)
}

// Owner is a free data retrieval call binding the contract method 0x8da5cb5b.
//
// Solidity: function owner() view returns(address)
func (_Contract *ContractCaller) Owner(opts *bind.CallOpts) (common.Address, error) {
	var out []interface{}
	err := _Contract.contract.Call(opts, &out, "owner")

	if err != nil {
		return *new(common.Address), err
	}

	out0 := *abi.ConvertType(out[0], new(common.Address)).(*common.Address)

	return out0, err

}

// Owner is a free data retrieval call binding the contract method 0x8da5cb5b.
//
// Solidity: function owner() view returns(address)
func (_Contract *ContractSession) Owner() (common.Address, error) {
	return _Contract.Contract.Owner(&_Contract.CallOpts)
}

// Owner is a free data retrieval call binding the contract method 0x8da5cb5b.
//
// Solidity: function owner() view returns(address)
func (_Contract *ContractCallerSession) Owner() (common.Address, error) {
	return _Contract.Contract.Owner(&_Contract.CallOpts)
}

// Profit is a free data retrieval call binding the contract method 0x27e97abc.
//
// Solidity: function profit(address owner, address token) view returns(uint256 balance)
func (_Contract *ContractCaller) Profit(opts *bind.CallOpts, owner common.Address, token common.Address) (*big.Int, error) {
	var out []interface{}
	err := _Contract.contract.Call(opts, &out, "profit", owner, token)

	if err != nil {
		return *new(*big.Int), err
	}

	out0 := *abi.ConvertType(out[0], new(*big.Int)).(**big.Int)

	return out0, err

}

// Profit is a free data retrieval call binding the contract method 0x27e97abc.
//
// Solidity: function profit(address owner, address token) view returns(uint256 balance)
func (_Contract *ContractSession) Profit(owner common.Address, token common.Address) (*big.Int, error) {
	return _Contract.Contract.Profit(&_Contract.CallOpts, owner, token)
}

// Profit is a free data retrieval call binding the contract method 0x27e97abc.
//
// Solidity: function profit(address owner, address token) view returns(uint256 balance)
func (_Contract *ContractCallerSession) Profit(owner common.Address, token common.Address) (*big.Int, error) {
	return _Contract.Contract.Profit(&_Contract.CallOpts, owner, token)
}

// ChangeProtocolFee is a paid mutator transaction binding the contract method 0xfe687475.
//
// Solidity: function changeProtocolFee(uint256 newProtocolFee) returns()
func (_Contract *ContractTransactor) ChangeProtocolFee(opts *bind.TransactOpts, newProtocolFee *big.Int) (*types.Transaction, error) {
	return _Contract.contract.Transact(opts, "changeProtocolFee", newProtocolFee)
}

// ChangeProtocolFee is a paid mutator transaction binding the contract method 0xfe687475.
//
// Solidity: function changeProtocolFee(uint256 newProtocolFee) returns()
func (_Contract *ContractSession) ChangeProtocolFee(newProtocolFee *big.Int) (*types.Transaction, error) {
	return _Contract.Contract.ChangeProtocolFee(&_Contract.TransactOpts, newProtocolFee)
}

// ChangeProtocolFee is a paid mutator transaction binding the contract method 0xfe687475.
//
// Solidity: function changeProtocolFee(uint256 newProtocolFee) returns()
func (_Contract *ContractTransactorSession) ChangeProtocolFee(newProtocolFee *big.Int) (*types.Transaction, error) {
	return _Contract.Contract.ChangeProtocolFee(&_Contract.TransactOpts, newProtocolFee)
}

// ChangeRefferalFee is a paid mutator transaction binding the contract method 0xe4ba7e1b.
//
// Solidity: function changeRefferalFee((uint256,uint256) newRefferalFee) returns()
func (_Contract *ContractTransactor) ChangeRefferalFee(opts *bind.TransactOpts, newRefferalFee MultiswapRouterRefferalFee) (*types.Transaction, error) {
	return _Contract.contract.Transact(opts, "changeRefferalFee", newRefferalFee)
}

// ChangeRefferalFee is a paid mutator transaction binding the contract method 0xe4ba7e1b.
//
// Solidity: function changeRefferalFee((uint256,uint256) newRefferalFee) returns()
func (_Contract *ContractSession) ChangeRefferalFee(newRefferalFee MultiswapRouterRefferalFee) (*types.Transaction, error) {
	return _Contract.Contract.ChangeRefferalFee(&_Contract.TransactOpts, newRefferalFee)
}

// ChangeRefferalFee is a paid mutator transaction binding the contract method 0xe4ba7e1b.
//
// Solidity: function changeRefferalFee((uint256,uint256) newRefferalFee) returns()
func (_Contract *ContractTransactorSession) ChangeRefferalFee(newRefferalFee MultiswapRouterRefferalFee) (*types.Transaction, error) {
	return _Contract.Contract.ChangeRefferalFee(&_Contract.TransactOpts, newRefferalFee)
}

// CollectProtocolFees is a paid mutator transaction binding the contract method 0x40a714ab.
//
// Solidity: function collectProtocolFees(address token, address recipient) returns()
func (_Contract *ContractTransactor) CollectProtocolFees(opts *bind.TransactOpts, token common.Address, recipient common.Address) (*types.Transaction, error) {
	return _Contract.contract.Transact(opts, "collectProtocolFees", token, recipient)
}

// CollectProtocolFees is a paid mutator transaction binding the contract method 0x40a714ab.
//
// Solidity: function collectProtocolFees(address token, address recipient) returns()
func (_Contract *ContractSession) CollectProtocolFees(token common.Address, recipient common.Address) (*types.Transaction, error) {
	return _Contract.Contract.CollectProtocolFees(&_Contract.TransactOpts, token, recipient)
}

// CollectProtocolFees is a paid mutator transaction binding the contract method 0x40a714ab.
//
// Solidity: function collectProtocolFees(address token, address recipient) returns()
func (_Contract *ContractTransactorSession) CollectProtocolFees(token common.Address, recipient common.Address) (*types.Transaction, error) {
	return _Contract.Contract.CollectProtocolFees(&_Contract.TransactOpts, token, recipient)
}

// CollectProtocolFees0 is a paid mutator transaction binding the contract method 0x8161b874.
//
// Solidity: function collectProtocolFees(address token, address recipient, uint256 amount) returns()
func (_Contract *ContractTransactor) CollectProtocolFees0(opts *bind.TransactOpts, token common.Address, recipient common.Address, amount *big.Int) (*types.Transaction, error) {
	return _Contract.contract.Transact(opts, "collectProtocolFees0", token, recipient, amount)
}

// CollectProtocolFees0 is a paid mutator transaction binding the contract method 0x8161b874.
//
// Solidity: function collectProtocolFees(address token, address recipient, uint256 amount) returns()
func (_Contract *ContractSession) CollectProtocolFees0(token common.Address, recipient common.Address, amount *big.Int) (*types.Transaction, error) {
	return _Contract.Contract.CollectProtocolFees0(&_Contract.TransactOpts, token, recipient, amount)
}

// CollectProtocolFees0 is a paid mutator transaction binding the contract method 0x8161b874.
//
// Solidity: function collectProtocolFees(address token, address recipient, uint256 amount) returns()
func (_Contract *ContractTransactorSession) CollectProtocolFees0(token common.Address, recipient common.Address, amount *big.Int) (*types.Transaction, error) {
	return _Contract.Contract.CollectProtocolFees0(&_Contract.TransactOpts, token, recipient, amount)
}

// CollectRefferalFees is a paid mutator transaction binding the contract method 0x4d05d8cb.
//
// Solidity: function collectRefferalFees(address token, address recipient, uint256 amount) returns()
func (_Contract *ContractTransactor) CollectRefferalFees(opts *bind.TransactOpts, token common.Address, recipient common.Address, amount *big.Int) (*types.Transaction, error) {
	return _Contract.contract.Transact(opts, "collectRefferalFees", token, recipient, amount)
}

// CollectRefferalFees is a paid mutator transaction binding the contract method 0x4d05d8cb.
//
// Solidity: function collectRefferalFees(address token, address recipient, uint256 amount) returns()
func (_Contract *ContractSession) CollectRefferalFees(token common.Address, recipient common.Address, amount *big.Int) (*types.Transaction, error) {
	return _Contract.Contract.CollectRefferalFees(&_Contract.TransactOpts, token, recipient, amount)
}

// CollectRefferalFees is a paid mutator transaction binding the contract method 0x4d05d8cb.
//
// Solidity: function collectRefferalFees(address token, address recipient, uint256 amount) returns()
func (_Contract *ContractTransactorSession) CollectRefferalFees(token common.Address, recipient common.Address, amount *big.Int) (*types.Transaction, error) {
	return _Contract.Contract.CollectRefferalFees(&_Contract.TransactOpts, token, recipient, amount)
}

// CollectRefferalFees0 is a paid mutator transaction binding the contract method 0xfd69f7ad.
//
// Solidity: function collectRefferalFees(address token, address recipient) returns()
func (_Contract *ContractTransactor) CollectRefferalFees0(opts *bind.TransactOpts, token common.Address, recipient common.Address) (*types.Transaction, error) {
	return _Contract.contract.Transact(opts, "collectRefferalFees0", token, recipient)
}

// CollectRefferalFees0 is a paid mutator transaction binding the contract method 0xfd69f7ad.
//
// Solidity: function collectRefferalFees(address token, address recipient) returns()
func (_Contract *ContractSession) CollectRefferalFees0(token common.Address, recipient common.Address) (*types.Transaction, error) {
	return _Contract.Contract.CollectRefferalFees0(&_Contract.TransactOpts, token, recipient)
}

// CollectRefferalFees0 is a paid mutator transaction binding the contract method 0xfd69f7ad.
//
// Solidity: function collectRefferalFees(address token, address recipient) returns()
func (_Contract *ContractTransactorSession) CollectRefferalFees0(token common.Address, recipient common.Address) (*types.Transaction, error) {
	return _Contract.Contract.CollectRefferalFees0(&_Contract.TransactOpts, token, recipient)
}

// Multiswap is a paid mutator transaction binding the contract method 0x8a3c8e5f.
//
// Solidity: function multiswap((uint256,uint256,address,bytes32[],address) data) returns()
func (_Contract *ContractTransactor) Multiswap(opts *bind.TransactOpts, data MultiswapRouterMultiswapCalldata) (*types.Transaction, error) {
	return _Contract.contract.Transact(opts, "multiswap", data)
}

// Multiswap is a paid mutator transaction binding the contract method 0x8a3c8e5f.
//
// Solidity: function multiswap((uint256,uint256,address,bytes32[],address) data) returns()
func (_Contract *ContractSession) Multiswap(data MultiswapRouterMultiswapCalldata) (*types.Transaction, error) {
	return _Contract.Contract.Multiswap(&_Contract.TransactOpts, data)
}

// Multiswap is a paid mutator transaction binding the contract method 0x8a3c8e5f.
//
// Solidity: function multiswap((uint256,uint256,address,bytes32[],address) data) returns()
func (_Contract *ContractTransactorSession) Multiswap(data MultiswapRouterMultiswapCalldata) (*types.Transaction, error) {
	return _Contract.Contract.Multiswap(&_Contract.TransactOpts, data)
}

// Partswap is a paid mutator transaction binding the contract method 0xe8f599f2.
//
// Solidity: function partswap((uint256,uint256,address,address,uint256[],bytes32[],address) data) returns()
func (_Contract *ContractTransactor) Partswap(opts *bind.TransactOpts, data MultiswapRouterPartswapCalldata) (*types.Transaction, error) {
	return _Contract.contract.Transact(opts, "partswap", data)
}

// Partswap is a paid mutator transaction binding the contract method 0xe8f599f2.
//
// Solidity: function partswap((uint256,uint256,address,address,uint256[],bytes32[],address) data) returns()
func (_Contract *ContractSession) Partswap(data MultiswapRouterPartswapCalldata) (*types.Transaction, error) {
	return _Contract.Contract.Partswap(&_Contract.TransactOpts, data)
}

// Partswap is a paid mutator transaction binding the contract method 0xe8f599f2.
//
// Solidity: function partswap((uint256,uint256,address,address,uint256[],bytes32[],address) data) returns()
func (_Contract *ContractTransactorSession) Partswap(data MultiswapRouterPartswapCalldata) (*types.Transaction, error) {
	return _Contract.Contract.Partswap(&_Contract.TransactOpts, data)
}

// TransferOwnership is a paid mutator transaction binding the contract method 0xf2fde38b.
//
// Solidity: function transferOwnership(address newOwner) returns()
func (_Contract *ContractTransactor) TransferOwnership(opts *bind.TransactOpts, newOwner common.Address) (*types.Transaction, error) {
	return _Contract.contract.Transact(opts, "transferOwnership", newOwner)
}

// TransferOwnership is a paid mutator transaction binding the contract method 0xf2fde38b.
//
// Solidity: function transferOwnership(address newOwner) returns()
func (_Contract *ContractSession) TransferOwnership(newOwner common.Address) (*types.Transaction, error) {
	return _Contract.Contract.TransferOwnership(&_Contract.TransactOpts, newOwner)
}

// TransferOwnership is a paid mutator transaction binding the contract method 0xf2fde38b.
//
// Solidity: function transferOwnership(address newOwner) returns()
func (_Contract *ContractTransactorSession) TransferOwnership(newOwner common.Address) (*types.Transaction, error) {
	return _Contract.Contract.TransferOwnership(&_Contract.TransactOpts, newOwner)
}

// Fallback is a paid mutator transaction binding the contract fallback function.
//
// Solidity: fallback() returns()
func (_Contract *ContractTransactor) Fallback(opts *bind.TransactOpts, calldata []byte) (*types.Transaction, error) {
	return _Contract.contract.RawTransact(opts, calldata)
}

// Fallback is a paid mutator transaction binding the contract fallback function.
//
// Solidity: fallback() returns()
func (_Contract *ContractSession) Fallback(calldata []byte) (*types.Transaction, error) {
	return _Contract.Contract.Fallback(&_Contract.TransactOpts, calldata)
}

// Fallback is a paid mutator transaction binding the contract fallback function.
//
// Solidity: fallback() returns()
func (_Contract *ContractTransactorSession) Fallback(calldata []byte) (*types.Transaction, error) {
	return _Contract.Contract.Fallback(&_Contract.TransactOpts, calldata)
}

// ContractOwnershipTransferredIterator is returned from FilterOwnershipTransferred and is used to iterate over the raw logs and unpacked data for OwnershipTransferred events raised by the Contract contract.
type ContractOwnershipTransferredIterator struct {
	Event *ContractOwnershipTransferred // Event containing the contract specifics and raw log

	contract *bind.BoundContract // Generic contract to use for unpacking event data
	event    string              // Event name to use for unpacking event data

	logs chan types.Log        // Log channel receiving the found contract events
	sub  ethereum.Subscription // Subscription for errors, completion and termination
	done bool                  // Whether the subscription completed delivering logs
	fail error                 // Occurred error to stop iteration
}

// Next advances the iterator to the subsequent event, returning whether there
// are any more events found. In case of a retrieval or parsing error, false is
// returned and Error() can be queried for the exact failure.
func (it *ContractOwnershipTransferredIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(ContractOwnershipTransferred)
			if err := it.contract.UnpackLog(it.Event, it.event, log); err != nil {
				it.fail = err
				return false
			}
			it.Event.Raw = log
			return true

		default:
			return false
		}
	}
	// Iterator still in progress, wait for either a data or an error event
	select {
	case log := <-it.logs:
		it.Event = new(ContractOwnershipTransferred)
		if err := it.contract.UnpackLog(it.Event, it.event, log); err != nil {
			it.fail = err
			return false
		}
		it.Event.Raw = log
		return true

	case err := <-it.sub.Err():
		it.done = true
		it.fail = err
		return it.Next()
	}
}

// Error returns any retrieval or parsing error occurred during filtering.
func (it *ContractOwnershipTransferredIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *ContractOwnershipTransferredIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// ContractOwnershipTransferred represents a OwnershipTransferred event raised by the Contract contract.
type ContractOwnershipTransferred struct {
	PreviousOwner common.Address
	NewOwner      common.Address
	Raw           types.Log // Blockchain specific contextual infos
}

// FilterOwnershipTransferred is a free log retrieval operation binding the contract event 0x8be0079c531659141344cd1fd0a4f28419497f9722a3daafe3b4186f6b6457e0.
//
// Solidity: event OwnershipTransferred(address indexed previousOwner, address indexed newOwner)
func (_Contract *ContractFilterer) FilterOwnershipTransferred(opts *bind.FilterOpts, previousOwner []common.Address, newOwner []common.Address) (*ContractOwnershipTransferredIterator, error) {

	var previousOwnerRule []interface{}
	for _, previousOwnerItem := range previousOwner {
		previousOwnerRule = append(previousOwnerRule, previousOwnerItem)
	}
	var newOwnerRule []interface{}
	for _, newOwnerItem := range newOwner {
		newOwnerRule = append(newOwnerRule, newOwnerItem)
	}

	logs, sub, err := _Contract.contract.FilterLogs(opts, "OwnershipTransferred", previousOwnerRule, newOwnerRule)
	if err != nil {
		return nil, err
	}
	return &ContractOwnershipTransferredIterator{contract: _Contract.contract, event: "OwnershipTransferred", logs: logs, sub: sub}, nil
}

// WatchOwnershipTransferred is a free log subscription operation binding the contract event 0x8be0079c531659141344cd1fd0a4f28419497f9722a3daafe3b4186f6b6457e0.
//
// Solidity: event OwnershipTransferred(address indexed previousOwner, address indexed newOwner)
func (_Contract *ContractFilterer) WatchOwnershipTransferred(opts *bind.WatchOpts, sink chan<- *ContractOwnershipTransferred, previousOwner []common.Address, newOwner []common.Address) (event.Subscription, error) {

	var previousOwnerRule []interface{}
	for _, previousOwnerItem := range previousOwner {
		previousOwnerRule = append(previousOwnerRule, previousOwnerItem)
	}
	var newOwnerRule []interface{}
	for _, newOwnerItem := range newOwner {
		newOwnerRule = append(newOwnerRule, newOwnerItem)
	}

	logs, sub, err := _Contract.contract.WatchLogs(opts, "OwnershipTransferred", previousOwnerRule, newOwnerRule)
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(ContractOwnershipTransferred)
				if err := _Contract.contract.UnpackLog(event, "OwnershipTransferred", log); err != nil {
					return err
				}
				event.Raw = log

				select {
				case sink <- event:
				case err := <-sub.Err():
					return err
				case <-quit:
					return nil
				}
			case err := <-sub.Err():
				return err
			case <-quit:
				return nil
			}
		}
	}), nil
}

// ParseOwnershipTransferred is a log parse operation binding the contract event 0x8be0079c531659141344cd1fd0a4f28419497f9722a3daafe3b4186f6b6457e0.
//
// Solidity: event OwnershipTransferred(address indexed previousOwner, address indexed newOwner)
func (_Contract *ContractFilterer) ParseOwnershipTransferred(log types.Log) (*ContractOwnershipTransferred, error) {
	event := new(ContractOwnershipTransferred)
	if err := _Contract.contract.UnpackLog(event, "OwnershipTransferred", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}
