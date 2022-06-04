require("dotenv").config();
const hre = require("hardhat");

const main = async () => {
	try {
		const nftContractFactory = await hre.ethers.getContractFactory("BullBear");
		const nftContract = await nftContractFactory.deploy(
			300,
			"0xece365b379e1dd183b20fc5f022230c044d51404",
			process.env.SUBSCRIPTION_ID,
			"0x6168499c0cFfCaCD319c818142124B7A15E857ab"
		);
		await nftContract.deployed();

		console.log("Contract deployed to:", nftContract.address);
		process.exit(0);
	} catch (error) {
		console.log(error);
		process.exit(1);
	}
};

main();
