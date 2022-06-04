const { expect } = require("chai");
const { BigNumber, FixedNumber } = require("ethers");
const { ethers, network } = require("hardhat");

describe("Bull&Bear", () => {
	let vrfContract;
	let contract;
	let priceFeedContract;
	let owner;
	let user;

	beforeEach(async () => {
		const PriceFeed = await ethers.getContractFactory("MockV3Aggregator");
		const priceFeed = await PriceFeed.deploy(8, 2972151000000);
		priceFeedContract = await priceFeed.deployed();

		const VRF = await ethers.getContractFactory("VRFCoordinatorV2Mock");
		const vrf = await VRF.deploy(
			FixedNumber.fromString("0.1", "fixed128x18"),
			FixedNumber.fromString("0.000000001", "fixed128x18")
		);
		vrfContract = await vrf.deployed();

		await vrfContract.createSubscription();
		await vrfContract.fundSubscription(1, FixedNumber.fromString("10", "fixed128x18"));

		const BullBear = await ethers.getContractFactory("BullBear");
		const bullBear = await BullBear.deploy(10, priceFeedContract.address, 1, vrfContract.address);
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

	it("should update the metadata of nft to one of the bears when price feed has gone down", async () => {
		await contract.safeMint(user.address);

		await network.provider.send("evm_increaseTime", [15000]);
		await network.provider.send("evm_mine");

		await priceFeedContract.updateAnswer(1972151000000);
		await contract.performUpkeep([]);

		await vrfContract.fulfillRandomWords(1, contract.address);

		expect(await contract.tokenURI(0)).to.be.oneOf([
			"https://ipfs.filebase.io/ipfs/bafkreib34nlgc2ahuu524ef3pupziqzm4wihl5hp2ih245wghytjl2oeva",
			"https://ipfs.filebase.io/ipfs/bafkreigcvajzfkyb7flg4zldjexvat5vycyyznfkf4z73unnbybtw2grou",
			"https://ipfs.filebase.io/ipfs/bafkreibfz66q2pkzvlvwz2lrp72zz2aesiniba5asu7ewrm74tyb2slgdm",
		]);
	});

	it("should change the price feed (down-up-down-up), making sure that it is selecting a random nft on the changes", async () => {
		let passing = true;

		await contract.safeMint(user.address);

		//down
		await network.provider.send("evm_increaseTime", [15000]);
		await network.provider.send("evm_mine");
		await priceFeedContract.updateAnswer(1972151000000);
		await contract.performUpkeep([]);
		await vrfContract.fulfillRandomWords(1, contract.address);
		console.log("Bear 1: ", await contract.tokenURI(0));
		if (
			!expect(await contract.tokenURI(0)).to.be.oneOf([
				"https://ipfs.filebase.io/ipfs/bafkreib34nlgc2ahuu524ef3pupziqzm4wihl5hp2ih245wghytjl2oeva",
				"https://ipfs.filebase.io/ipfs/bafkreigcvajzfkyb7flg4zldjexvat5vycyyznfkf4z73unnbybtw2grou",
				"https://ipfs.filebase.io/ipfs/bafkreibfz66q2pkzvlvwz2lrp72zz2aesiniba5asu7ewrm74tyb2slgdm",
			])
		) {
			passing = false;
		}

		//up
		await network.provider.send("evm_increaseTime", [15000]);
		await network.provider.send("evm_mine");
		await priceFeedContract.updateAnswer(3972151000000);
		await contract.performUpkeep([]);
		await vrfContract.fulfillRandomWords(2, contract.address);
		console.log("Bull 1: ", await contract.tokenURI(0));
		if (
			!expect(await contract.tokenURI(0)).to.be.oneOf([
				"https://ipfs.filebase.io/ipfs/bafkreic3japs25s27r5k4ptt7ydein427quoceyo4rp6ac3m3umpw3msqu",
				"https://ipfs.filebase.io/ipfs/bafkreiaafatqttb3gvvq6fh3q27koiq3i5tn2xr5kz3ssoi55gp6jp5a24",
				"https://ipfs.filebase.io/ipfs/bafkreidihcyg5pu5ovbvtwrgyfkx4idimqqkbbikrhnhivfsgtejx4v7gi",
			])
		) {
			passing = false;
		}

		//down
		await network.provider.send("evm_increaseTime", [15000]);
		await network.provider.send("evm_mine");
		await priceFeedContract.updateAnswer(1972151000000);
		await contract.performUpkeep([]);
		await vrfContract.fulfillRandomWords(3, contract.address);
		console.log("Bear 2: ", await contract.tokenURI(0));
		if (
			!expect(await contract.tokenURI(0)).to.be.oneOf([
				"https://ipfs.filebase.io/ipfs/bafkreib34nlgc2ahuu524ef3pupziqzm4wihl5hp2ih245wghytjl2oeva",
				"https://ipfs.filebase.io/ipfs/bafkreigcvajzfkyb7flg4zldjexvat5vycyyznfkf4z73unnbybtw2grou",
				"https://ipfs.filebase.io/ipfs/bafkreibfz66q2pkzvlvwz2lrp72zz2aesiniba5asu7ewrm74tyb2slgdm",
			])
		) {
			passing = false;
		}

		//up
		await network.provider.send("evm_increaseTime", [15000]);
		await network.provider.send("evm_mine");
		await priceFeedContract.updateAnswer(3972151000000);
		await contract.performUpkeep([]);
		await vrfContract.fulfillRandomWords(4, contract.address);
		console.log("Bull 2: ", await contract.tokenURI(0));
		if (
			!expect(await contract.tokenURI(0)).to.be.oneOf([
				"https://ipfs.filebase.io/ipfs/bafkreic3japs25s27r5k4ptt7ydein427quoceyo4rp6ac3m3umpw3msqu",
				"https://ipfs.filebase.io/ipfs/bafkreiaafatqttb3gvvq6fh3q27koiq3i5tn2xr5kz3ssoi55gp6jp5a24",
				"https://ipfs.filebase.io/ipfs/bafkreidihcyg5pu5ovbvtwrgyfkx4idimqqkbbikrhnhivfsgtejx4v7gi",
			])
		) {
			passing = false;
		}

		expect(passing);
	});
});
