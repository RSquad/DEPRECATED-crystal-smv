import { TonClient } from "@tonclient/core";
import { createClient, TonContract } from "@rsquad/ton-utils";
import { callThroughMultisig } from "@rsquad/ton-utils/dist/net";
import pkgTestSmvRoot from "../../ton-packages/TestSmvRoot.package";
import pkgTestProposal from "../../ton-packages/TestProposal.package";
import pkgPadawan from "../../ton-packages/Padawan.package";
import { expect } from "chai";
import { EMPTY_ADDRESS } from "@rsquad/ton-utils/dist/constants";
import { isAddrActive, sleep } from "@rsquad/ton-utils/dist/common";
import { createMultisig, deployDirectly } from "../utils";

describe("Padawan unit test", () => {
  let client: TonClient;
  let smcSafeMultisigWallet: TonContract;
  let smcTestSmvRoot: TonContract;
  let smcTestProposal: TonContract;
  let smcTestProposal2: TonContract;
  let smcPadawan: TonContract;

  const getPadawanData = async () => {
    const totalVotes = (await smcPadawan.run({ functionName: "_totalVotes" }))
      .value._totalVotes;
    const requestedVotes = (
      await smcPadawan.run({ functionName: "_requestedVotes" })
    ).value._requestedVotes;
    const lockedVotes = (await smcPadawan.run({ functionName: "_lockedVotes" }))
      .value._lockedVotes;
    const proposals = (await smcPadawan.run({ functionName: "_proposals" }))
      .value._proposals;
    return {
      totalVotes,
      requestedVotes,
      lockedVotes,
      proposals,
    };
  };

  const deposit = async (
    votes: number,
    {
      additionalVotes,
      additionalValue,
    }: { additionalVotes?: number; additionalValue?: number } = {}
  ) => {
    const { totalVotes: totalVotesBefore } = await getPadawanData();

    await callThroughMultisig({
      client,
      smcSafeMultisigWallet,
      abi: smcPadawan.tonPackage.abi,
      functionName: "deposit",
      input: {
        votes: votes + (additionalVotes || 0),
      },
      dest: smcPadawan.address,
      value: votes * 1_000_000_000 + 200_000_000 + (additionalValue || 0),
    });

    const { totalVotes: totalVotesAfter } = await getPadawanData();
    return { totalVotesBefore, totalVotesAfter };
  };

  const reclaim = async (
    votes: number,
    { additionalValue }: { additionalValue?: number } = {}
  ) => {
    const {
      totalVotes: totalVotesBefore,
      lockedVotes: lockedVotesBefore,
      proposals: proposalsBefore,
    } = await getPadawanData();

    await callThroughMultisig({
      client,
      smcSafeMultisigWallet,
      abi: smcPadawan.tonPackage.abi,
      functionName: "reclaim",
      input: {
        votes,
        returnTo: smcSafeMultisigWallet.address,
      },
      dest: smcPadawan.address,
      value: 400_000_000 + (additionalValue || 0),
    });

    const {
      totalVotes: totalVotesAfter,
      lockedVotes: lockedVotesAfter,
      proposals: proposalsAfter,
    } = await getPadawanData();

    return {
      totalVotesBefore,
      totalVotesAfter,
      lockedVotesBefore,
      lockedVotesAfter,
      proposalsBefore,
      proposalsAfter,
    };
  };

  const vote = async (votes: number, { smc }: { smc?: TonContract } = {}) => {
    const { lockedVotes: lockedVotesBefore, proposals: proposalsBefore } =
      await getPadawanData();
    await callThroughMultisig({
      client,
      smcSafeMultisigWallet,
      abi: smcPadawan.tonPackage.abi,
      functionName: "vote",
      input: {
        addrProposal: (smc || smcTestProposal).address,
        choice: true,
        votes: votes,
      },
      dest: smcPadawan.address,
      value: 1_500_000_000,
    });
    const { lockedVotes: lockedVotesAfter, proposals: proposalsAfter } =
      await getPadawanData();

    return {
      lockedVotesBefore,
      lockedVotesAfter,
      proposalsBefore,
      proposalsAfter,
    };
  };

  before(async () => {
    client = createClient();
    smcSafeMultisigWallet = createMultisig(client);

    const codePadawan = (
      await client.boc.get_code_from_tvc({ tvc: pkgPadawan.image })
    ).code;
    const testProposalDeployInput = {
      value0: "",
      value1: 0,
      value2: EMPTY_ADDRESS,
      value3: "",
      value4: "",
      codePadawan,
    };

    smcTestSmvRoot = await deployDirectly({
      client,
      smcSafeMultisigWallet,
      name: "TestSmvRoot",
      tonPackage: pkgTestSmvRoot,
      input: {
        codePadawan,
      },
    });

    smcTestProposal = await deployDirectly({
      client,
      smcSafeMultisigWallet,
      name: "TestProposal",
      tonPackage: pkgTestProposal,
      input: testProposalDeployInput,
    });

    smcTestProposal2 = await deployDirectly({
      client,
      smcSafeMultisigWallet,
      name: "TestProposal2",
      tonPackage: pkgTestProposal,
      input: testProposalDeployInput,
    });
  });

  it("deploy Padawan", async () => {
    await callThroughMultisig({
      client,
      smcSafeMultisigWallet,
      abi: smcTestSmvRoot.tonPackage.abi,
      functionName: "deployPadawan",
      input: {
        addrOwner: smcSafeMultisigWallet.address,
      },
      dest: smcTestSmvRoot.address,
      value: 3_000_000_000,
    });

    smcPadawan = new TonContract({
      client,
      name: "Padawan",
      tonPackage: pkgPadawan,
      address: (
        await smcTestSmvRoot.run({
          functionName: "resolvePadawan",
          input: {
            addrRoot: smcTestSmvRoot.address,
            addrOwner: smcSafeMultisigWallet.address,
          },
        })
      ).value.addrPadawan,
    });

    expect(
      await isAddrActive(client, smcPadawan.address),
      `Padawan ${smcPadawan.address} isn't active`
    ).to.be.true;
    console.log(`Padawan has been deployed: ${smcPadawan.address}`);
  });

  describe("Deposits and reclaims", () => {
    it("deposit 99 votes", async () => {
      const votes = 99;
      const { totalVotesAfter, totalVotesBefore } = await deposit(votes);
      expect(totalVotesAfter - totalVotesBefore).to.be.eq(votes);
    });

    it("try to reclaim more than deposited (100 votes)", async () => {
      const votes = 100;
      const { totalVotesAfter, totalVotesBefore } = await reclaim(votes);
      expect(totalVotesAfter).to.be.eq(totalVotesBefore);
    });

    it("reclaim 99 votes", async () => {
      const votes = 99;
      const { totalVotesAfter, totalVotesBefore } = await reclaim(votes);
      expect(totalVotesAfter - totalVotesBefore).to.be.eq(-votes);
    });

    it("deposit 10 crystals", async () => {
      const votes = 10;
      const { totalVotesAfter, totalVotesBefore } = await deposit(votes);
      expect(totalVotesAfter - totalVotesBefore).to.be.eq(votes);
    });

    it("try to deposit more votes that value (11 votes with 10 crystals)", async () => {
      const votes = 10;
      const { totalVotesAfter, totalVotesBefore } = await deposit(votes, {
        additionalVotes: 1,
      });
      expect(totalVotesAfter).to.be.eq(totalVotesBefore);
    });

    it("try to deposit more votes that value (10 votes with 9 crystals)", async () => {
      const votes = 10;
      const { totalVotesAfter, totalVotesBefore } = await deposit(votes, {
        additionalValue: -1_000_000_000,
      });
      expect(totalVotesAfter).to.be.eq(totalVotesBefore);
    });
  });

  describe("Voting", () => {
    it("try to vote with more votes than deposited (11 votes)", async () => {
      const votes = 11;
      const { lockedVotesAfter, lockedVotesBefore } = await vote(votes);
      expect(lockedVotesAfter).to.be.eq(lockedVotesBefore);
    });

    it("vote with 5 of 10 votes", async () => {
      const votes = 5;
      const { lockedVotesAfter, lockedVotesBefore, proposalsAfter } =
        await vote(votes);
      expect(+proposalsAfter[smcTestProposal.address]).to.be.eq(votes);
      expect(lockedVotesAfter - lockedVotesBefore).to.be.eq(votes);
    });

    it("vote with remaiging 5 votes", async () => {
      const votes = 5;
      const {
        lockedVotesAfter,
        lockedVotesBefore,
        proposalsAfter,
        proposalsBefore,
      } = await vote(votes);
      expect(
        proposalsAfter[smcTestProposal.address] -
          proposalsBefore[smcTestProposal.address]
      ).to.be.eq(votes);
      expect(lockedVotesAfter - lockedVotesBefore).to.be.eq(votes);
    });

    it("try to vote with 5 votes without votes on balance", async () => {
      const votes = 5;
      const {
        lockedVotesAfter,
        lockedVotesBefore,
        proposalsAfter,
        proposalsBefore,
      } = await vote(votes);
      expect(proposalsAfter[smcTestProposal.address]).to.be.eq(
        proposalsBefore[smcTestProposal.address]
      );
      expect(lockedVotesAfter).to.be.eq(lockedVotesBefore);
    });

    it("vote for second proposal with 5 votes", async () => {
      const votes = 5;
      const { lockedVotesAfter, lockedVotesBefore, proposalsAfter } =
        await vote(votes, { smc: smcTestProposal2 });
      expect(+proposalsAfter[smcTestProposal2.address]).to.be.eq(votes);
      expect(lockedVotesAfter).to.be.eq(lockedVotesBefore);
    });

    it("deposit 10 votes", async () => {
      const votes = 10;
      const { totalVotesAfter, totalVotesBefore } = await deposit(votes);
      expect(totalVotesAfter - totalVotesBefore).to.be.eq(votes);
    });

    it("vote for second proposal with 15 votes", async () => {
      const votes = 15;
      const {
        lockedVotesAfter,
        lockedVotesBefore,
        proposalsAfter,
        proposalsBefore,
      } = await vote(votes, { smc: smcTestProposal2 });
      expect(
        proposalsAfter[smcTestProposal2.address] -
          proposalsBefore[smcTestProposal2.address]
      ).to.be.eq(votes);
      expect(lockedVotesAfter - lockedVotesBefore).to.be.eq(10);
    });

    it("update locked votes (proposals are finished)", async () => {
      await callThroughMultisig({
        client,
        smcSafeMultisigWallet,
        abi: smcPadawan.tonPackage.abi,
        functionName: "updateLockedVotes",
        input: {},
        dest: smcPadawan.address,
        value: 800_000_000,
      });
      await sleep(2000);
      const { lockedVotes: lockedVotesAfter, proposals: proposalsAfter } =
        await getPadawanData();
      expect(+lockedVotesAfter).to.be.eq(0);
      expect(proposalsAfter).to.be.empty;
    });

    it("reclaim add 20 votes", async () => {
      const votes = 10;
      const { totalVotesAfter, totalVotesBefore, lockedVotesAfter } =
        await reclaim(votes, { additionalValue: 400_000_000 });
      expect(+totalVotesAfter).to.be.eq(totalVotesBefore - votes);
      expect(+lockedVotesAfter).to.be.eq(0);
    });
  });
});
