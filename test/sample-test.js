const { expect } = require("chai");
const { ethers, network } = require("hardhat");

describe("Bull&Bear", () => {
	let contract;
	let priceFeedContract;
	let owner;
	let user;

	beforeEach(async () => {
		const PriceFeed = await ethers.getContractFactory("MockV3Aggregator");
		const priceFeed = await PriceFeed.deploy(8, 2972151000000);
		priceFeedContract = await priceFeed.deployed();

		const BullBear = await ethers.getContractFactory("BullBear");
		const bullBear = await BullBear.deploy(10, priceFeedContract.address);
		contract = await bullBear.deployed();

		[owner, user] = await ethers.getSigners();
	});

	//Test for the mint of NFT
	it("should mint 1 NFT and assign ownership to user", async () => {
		await contract.safeMint(user.address);
		const balance = await contract.balanceOf(user.address);
		expect(balance).to.equal(1) &&
			expect(await contract.tokenURI(0)).to.equal(
				"https://ipfs.filebase.io/ipfs/bafkreic3japs25s27r5k4ptt7ydein427quoceyo4rp6ac3m3umpw3msqu"
			);
	});

	it("should update the metadata of nft to bear when price feed has gone down", async () => {
		await contract.safeMint(user.address);

		await network.provider.send("evm_increaseTime", [15000]);
		await network.provider.send("evm_mine");

		await priceFeedContract.updateAnswer(1972151000000);
		await contract.performUpkeep([]);
		expect(await contract.tokenURI(0)).to.equal(
			"https://ipfs.filebase.io/ipfs/bafkreib34nlgc2ahuu524ef3pupziqzm4wihl5hp2ih245wghytjl2oeva"
		);
	});
});
