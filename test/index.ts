import { expect } from "chai";
import { ethers, waffle } from "hardhat";

describe("Non Fungible Nickname", function () {
  it("Should mint new name as owner", async function () {
    const [owner, addr1, addr2] = await ethers.getSigners();
    const Contract = await ethers.getContractFactory("NonFungibleNickname");
    const contract = await Contract.deploy();
    await contract.deployed();

    await contract.safeMint("non_fungible_user");

    expect(await contract.balanceOf(owner.address)).is.eq(1);
  });

  it("Should payed mint new name", async function () {
    const cost = ethers.utils.parseEther("0.02");
    const [owner, addr1, addr2] = await ethers.getSigners();
    const Contract = await ethers.getContractFactory("NonFungibleNickname");
    const contract = await Contract.deploy();
    await contract.deployed();

    await contract
      .connect(addr1)
      .safeMint("non_fungible_user", { value: cost });

    expect(await contract.connect(addr1).balanceOf(addr1.address)).is.eq(1);
  });

  it("shouldn't mint name with wrong price", async function () {
    const cost = ethers.utils.parseEther("0.01");
    const [owner, addr1, addr2] = await ethers.getSigners();
    const Contract = await ethers.getContractFactory("NonFungibleNickname");
    const contract = await Contract.deploy();
    await contract.deployed();

    await expect(
      contract.connect(addr1).safeMint("non_fungible_user", { value: cost })
    ).to.be.revertedWith("Non Fungible Nickname: wrong value");
  });

  it("Shouldn't mint two same name", async function () {
    const cost = ethers.utils.parseEther("0.02");
    const [owner, addr1, addr2] = await ethers.getSigners();
    const Contract = await ethers.getContractFactory("NonFungibleNickname");
    const contract = await Contract.deploy();
    await contract.deployed();

    await contract
      .connect(addr1)
      .safeMint("non_fungible_user", { value: cost });

    await expect(
      contract.connect(addr1).safeMint("non_fungible_user", { value: cost })
    ).to.be.revertedWith("ERC721: token already minted");
  });

  it("Should burn token", async function () {
    const [owner, addr1, addr2] = await ethers.getSigners();
    const Contract = await ethers.getContractFactory("NonFungibleNickname");
    const contract = await Contract.deploy();
    await contract.deployed();

    const transferTx = await contract.safeMint("non_fungible_user");
    const result = await transferTx.wait();
    const tokenId = result.events![0].args!.tokenId;

    expect(await contract.balanceOf(owner.address)).is.eq(1);

    await contract.burn(tokenId);

    expect(await contract.balanceOf(owner.address)).is.eq(0);
  });

  it("Shouldn't burn token", async function () {
    const [owner, addr1, addr2] = await ethers.getSigners();
    const Contract = await ethers.getContractFactory("NonFungibleNickname");
    const contract = await Contract.deploy();
    await contract.deployed();

    const transferTx = await contract.safeMint("non_fungible_user");
    const result = await transferTx.wait();
    const tokenId = result.events![0].args!.tokenId;

    expect(await contract.balanceOf(owner.address)).is.eq(1);

    await expect(contract.connect(addr1).burn(tokenId)).to.be.revertedWith(
      "Non Fungible Nickname: caller is not token owner nor approved"
    );

    expect(await contract.balanceOf(owner.address)).is.eq(1);
  });

  it("Shouldn't burn protected token", async function () {
    const [owner, addr1, addr2] = await ethers.getSigners();
    const Contract = await ethers.getContractFactory("NonFungibleNickname");
    const contract = await Contract.deploy();
    await contract.deployed();

    const transferTx = await contract.safeMint("non_fungible_user");
    const result = await transferTx.wait();
    const tokenId = result.events![0].args!.tokenId;

    expect(await contract.balanceOf(owner.address)).is.eq(1);

    await contract.protectFromFire(tokenId);

    await expect(contract.burn(tokenId)).to.be.revertedWith(
      "Non Fungible Nickname: this token protected"
    );

    expect(await contract.balanceOf(owner.address)).is.eq(1);
  });

  it("Should burn by voted token", async function () {
    const cost = ethers.utils.parseEther("0.02");

    const [owner, addr1, addr2] = await ethers.getSigners();
    const Contract = await ethers.getContractFactory("NonFungibleNickname");
    const contract = await Contract.deploy();
    await contract.deployed();

    const transferTx = await contract
      .connect(addr1)
      .safeMint("non_fungible_user", { value: cost });

    const result = await transferTx.wait();
    const tokenId = result.events![0].args!.tokenId;

    expect(await contract.balanceOf(addr1.address)).is.eq(1);

    await contract.burnByVoted(tokenId);

    expect(await contract.balanceOf(addr1.address)).is.eq(0);
  });

  it("Shouldn't burn protected by voted token", async function () {
    const cost = ethers.utils.parseEther("0.02");

    const [owner, addr1, addr2] = await ethers.getSigners();
    const Contract = await ethers.getContractFactory("NonFungibleNickname");
    const contract = await Contract.deploy();
    await contract.deployed();

    const transferTx = await contract
      .connect(addr1)
      .safeMint("non_fungible_user", { value: cost });

    const result = await transferTx.wait();
    const tokenId = result.events![0].args!.tokenId;

    expect(await contract.balanceOf(addr1.address)).is.eq(1);

    await contract.protectFromFire(tokenId);

    await expect(contract.burnByVoted(tokenId)).to.be.revertedWith(
      "Non Fungible Nickname: this token protected"
    );

    expect(await contract.balanceOf(addr1.address)).is.eq(1);
  });

  it("Should get token uri", async function () {
    const [owner, addr1, addr2] = await ethers.getSigners();
    const Contract = await ethers.getContractFactory("NonFungibleNickname");
    const contract = await Contract.deploy();
    await contract.deployed();
    const baseURI = "http://localhost:3000/tokens/";

    await contract.setBaseURI(baseURI);

    const transferTx = await contract.safeMint("non_fungible_user");
    const result = await transferTx.wait();
    const tokenId = result.events![0].args!.tokenId;

    expect(await contract.tokenURI(tokenId)).is.eq(baseURI + tokenId);

    // expect(await contract.balanceOf(owner.address)).is.eq(1);
  });

  it("Should payed mint new name", async function () {
    const cost = ethers.utils.parseEther("0.02");
    const [owner, addr1, addr2] = await ethers.getSigners();
    const Contract = await ethers.getContractFactory("NonFungibleNickname");
    const contract = await Contract.deploy();
    await contract.deployed();

    const provider = waffle.provider;
    const ownerOldBalance = await provider.getBalance(owner.address);

    await contract
      .connect(addr1)
      .safeMint("non_fungible_user", { value: cost });

    await contract.withdraw();

    const ownerNewBalance = await provider.getBalance(owner.address);

    expect(ownerNewBalance).is.gt(ownerOldBalance);
  });
});
