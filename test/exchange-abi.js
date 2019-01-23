const blockContractAbi = [
	{
		"constant": false,
		"inputs": [
			{
				"name": "symbolName",
				"type": "string"
			},
			{
				"name": "erc20TokenAddress",
				"type": "address"
			}
		],
		"name": "addToken",
		"outputs": [],
		"payable": false,
		"stateMutability": "nonpayable",
		"type": "function"
	},
	{
		"constant": false,
		"inputs": [
			{
				"name": "symbolName",
				"type": "string"
			},
			{
				"name": "priceInWei",
				"type": "uint256"
			},
			{
				"name": "amount",
				"type": "uint256"
			}
		],
		"name": "buyToken",
		"outputs": [],
		"payable": false,
		"stateMutability": "nonpayable",
		"type": "function"
	},
	{
		"constant": false,
		"inputs": [],
		"name": "depositEther",
		"outputs": [],
		"payable": true,
		"stateMutability": "payable",
		"type": "function"
	},
	{
		"constant": false,
		"inputs": [
			{
				"name": "symbolName",
				"type": "string"
			},
			{
				"name": "amount",
				"type": "uint256"
			}
		],
		"name": "depositToken",
		"outputs": [],
		"payable": false,
		"stateMutability": "nonpayable",
		"type": "function"
	},
	{
		"constant": false,
		"inputs": [
			{
				"name": "symbolName",
				"type": "string"
			}
		],
		"name": "getBalance",
		"outputs": [
			{
				"name": "",
				"type": "uint256"
			}
		],
		"payable": true,
		"stateMutability": "payable",
		"type": "function"
	},
	{
		"constant": false,
		"inputs": [
			{
				"name": "symbolName",
				"type": "string"
			}
		],
		"name": "getBuyOrderBook",
		"outputs": [
			{
				"components": [
					{
						"name": "price",
						"type": "uint256"
					},
					{
						"name": "amount",
						"type": "uint256"
					}
				],
				"name": "",
				"type": "tuple[]"
			}
		],
		"payable": false,
		"stateMutability": "nonpayable",
		"type": "function"
	},
	{
		"constant": false,
		"inputs": [],
		"name": "getEthBalanceInWei",
		"outputs": [
			{
				"name": "",
				"type": "uint256"
			}
		],
		"payable": false,
		"stateMutability": "nonpayable",
		"type": "function"
	},
	{
		"constant": false,
		"inputs": [
			{
				"name": "symbolName",
				"type": "string"
			}
		],
		"name": "getSymbolIndexOrThrow",
		"outputs": [
			{
				"name": "",
				"type": "uint8"
			}
		],
		"payable": false,
		"stateMutability": "nonpayable",
		"type": "function"
	},
	{
		"constant": false,
		"inputs": [
			{
				"name": "symbolName",
				"type": "string"
			}
		],
		"name": "hasToken",
		"outputs": [
			{
				"name": "",
				"type": "bool"
			}
		],
		"payable": false,
		"stateMutability": "nonpayable",
		"type": "function"
	},
	{
		"constant": false,
		"inputs": [
			{
				"name": "symbolName",
				"type": "string"
			},
			{
				"name": "priceInWei",
				"type": "uint256"
			},
			{
				"name": "amount",
				"type": "uint256"
			}
		],
		"name": "sellToken",
		"outputs": [],
		"payable": false,
		"stateMutability": "nonpayable",
		"type": "function"
	},
	{
		"constant": false,
		"inputs": [
			{
				"name": "amountInWei",
				"type": "uint256"
			}
		],
		"name": "withdrawEther",
		"outputs": [],
		"payable": false,
		"stateMutability": "nonpayable",
		"type": "function"
	},
	{
		"constant": false,
		"inputs": [
			{
				"name": "symbolName",
				"type": "string"
			},
			{
				"name": "amount",
				"type": "uint256"
			}
		],
		"name": "withdrawToken",
		"outputs": [],
		"payable": false,
		"stateMutability": "nonpayable",
		"type": "function"
	},
	{
		"anonymous": false,
		"inputs": [
			{
				"indexed": true,
				"name": "_from",
				"type": "address"
			},
			{
				"indexed": true,
				"name": "_symbolIndex",
				"type": "uint256"
			},
			{
				"indexed": false,
				"name": "_amount",
				"type": "uint256"
			},
			{
				"indexed": false,
				"name": "_timestamp",
				"type": "uint256"
			}
		],
		"name": "DepositForTokenReceived",
		"type": "event"
	},
	{
		"anonymous": false,
		"inputs": [
			{
				"indexed": true,
				"name": "_to",
				"type": "address"
			},
			{
				"indexed": true,
				"name": "_symbolIndex",
				"type": "uint256"
			},
			{
				"indexed": false,
				"name": "_amount",
				"type": "uint256"
			},
			{
				"indexed": false,
				"name": "_timestamp",
				"type": "uint256"
			}
		],
		"name": "WithdrawalToken",
		"type": "event"
	},
	{
		"anonymous": false,
		"inputs": [
			{
				"indexed": true,
				"name": "_from",
				"type": "address"
			},
			{
				"indexed": false,
				"name": "amount",
				"type": "uint256"
			},
			{
				"indexed": false,
				"name": "_timestamp",
				"type": "uint256"
			}
		],
		"name": "DepositForEthReceived",
		"type": "event"
	},
	{
		"anonymous": false,
		"inputs": [
			{
				"indexed": true,
				"name": "_to",
				"type": "address"
			},
			{
				"indexed": false,
				"name": "_amount",
				"type": "uint256"
			},
			{
				"indexed": false,
				"name": "_timestamp",
				"type": "uint256"
			}
		],
		"name": "WithdrawalEth",
		"type": "event"
	},
	{
		"anonymous": false,
		"inputs": [
			{
				"indexed": true,
				"name": "_symbolIndex",
				"type": "uint256"
			},
			{
				"indexed": true,
				"name": "_who",
				"type": "address"
			},
			{
				"indexed": false,
				"name": "_amountTokens",
				"type": "uint256"
			},
			{
				"indexed": false,
				"name": "_priceInWei",
				"type": "uint256"
			},
			{
				"indexed": false,
				"name": "_orderKey",
				"type": "uint256"
			}
		],
		"name": "LimitSellOrderCreated",
		"type": "event"
	},
	{
		"anonymous": false,
		"inputs": [
			{
				"indexed": true,
				"name": "_symbolIndex",
				"type": "uint256"
			},
			{
				"indexed": false,
				"name": "_amount",
				"type": "uint256"
			},
			{
				"indexed": false,
				"name": "_priceInWei",
				"type": "uint256"
			},
			{
				"indexed": false,
				"name": "_orderKey",
				"type": "uint256"
			}
		],
		"name": "SellOrderFulfilled",
		"type": "event"
	},
	{
		"anonymous": false,
		"inputs": [
			{
				"indexed": true,
				"name": "_symbolIndex",
				"type": "uint256"
			},
			{
				"indexed": false,
				"name": "_priceInWei",
				"type": "uint256"
			},
			{
				"indexed": false,
				"name": "_orderKey",
				"type": "uint256"
			}
		],
		"name": "SellOrderCanceled",
		"type": "event"
	},
	{
		"anonymous": false,
		"inputs": [
			{
				"indexed": true,
				"name": "_symbolIndex",
				"type": "uint256"
			},
			{
				"indexed": true,
				"name": "_who",
				"type": "address"
			},
			{
				"indexed": false,
				"name": "_amountTokens",
				"type": "uint256"
			},
			{
				"indexed": false,
				"name": "_priceInWei",
				"type": "uint256"
			},
			{
				"indexed": false,
				"name": "_orderKey",
				"type": "uint256"
			}
		],
		"name": "LimitBuyOrderCreated",
		"type": "event"
	},
	{
		"anonymous": false,
		"inputs": [
			{
				"indexed": true,
				"name": "_symbolIndex",
				"type": "uint256"
			},
			{
				"indexed": false,
				"name": "_amount",
				"type": "uint256"
			},
			{
				"indexed": false,
				"name": "_priceInWei",
				"type": "uint256"
			},
			{
				"indexed": false,
				"name": "_orderKey",
				"type": "uint256"
			}
		],
		"name": "BuyOrderFulfilled",
		"type": "event"
	},
	{
		"anonymous": false,
		"inputs": [
			{
				"indexed": true,
				"name": "_symbolIndex",
				"type": "uint256"
			},
			{
				"indexed": false,
				"name": "_priceInWei",
				"type": "uint256"
			},
			{
				"indexed": false,
				"name": "_orderKey",
				"type": "uint256"
			}
		],
		"name": "BuyOrderCanceled",
		"type": "event"
	},
	{
		"anonymous": false,
		"inputs": [
			{
				"indexed": false,
				"name": "_symbolIndex",
				"type": "uint256"
			},
			{
				"indexed": false,
				"name": "_token",
				"type": "string"
			},
			{
				"indexed": false,
				"name": "_timestamp",
				"type": "uint256"
			}
		],
		"name": "TokenAddedToSystem",
		"type": "event"
	}
]

module. exports = blockContractAbi;