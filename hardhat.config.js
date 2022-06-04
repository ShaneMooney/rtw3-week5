require("dotenv").config();
require("@nomiclabs/hardhat-waffle");
require("@nomiclabs/hardhat-etherscan");
require("hardhat-tracer");

module.exports = {
	solidity: {
		compilers: [
			{
				version: "0.8.4",
			},
			{
				version: "0.6.4",
			},
		],
	},
	networks: {
		rinkeby: {
			url: process.env.TESTNET_RPC,
			accounts: [process.env.PRIVATE_KEY],
		},
	},

	etherscan: {
		apiKey: process.env.RINKEBYSCAN_API_KEY,
	},
};
