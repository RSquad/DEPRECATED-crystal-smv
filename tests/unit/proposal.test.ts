import { TonClient } from "@tonclient/core";
import { createClient, TonContract } from "@rsquad/ton-utils";
import pkgProposal from "../../ton-packages/Proposal.package";
import pkgPadawan from "../../ton-packages/Padawan.package";
import pkgTestProposalFactory from "../../ton-packages/TestProposalFactory.package";
import pkgSmvRootStore from "../../ton-packages/SmvRootStore.package";
import pkgSmvRoot from "../../ton-packages/SmvRoot.package";
import { expect } from "chai";
import { createMultisig, deployDirectly } from "../utils";
import { isAddrActive, sleep } from "@rsquad/ton-utils/dist/common";
import {
  callThroughMultisig,
  sendThroughMultisig,
} from "@rsquad/ton-utils/dist/net";
import { EMPTY_ADDRESS } from "@rsquad/ton-utils/dist/constants";
import { utf8ToHex } from "@rsquad/ton-utils/dist/convert";

describe("Padawan unit test", () => {
  let client: TonClient;
  let smcSafeMultisigWallet: TonContract;
  let smcSmvRootStore: TonContract;
  let smcTestProposalFactory: TonContract;
  let smcPadawan: TonContract;
  let smcProposal: TonContract;
  let smcProposal2: TonContract;
  let smcSmvRoot: TonContract;

  const deposit = async (
    votes: number,
    {
      additionalVotes,
      additionalValue,
    }: { additionalVotes?: number; additionalValue?: number } = {}
  ) => {
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
  };

  before(async () => {
    client = createClient();
    smcSafeMultisigWallet = createMultisig(client);

    smcSmvRoot = new TonContract({
      client,
      name: "SmvRoot",
      tonPackage: pkgSmvRoot,
      keys: await client.crypto.generate_random_sign_keys(),
    });
    await smcSmvRoot.calcAddress();

    smcTestProposalFactory = await deployDirectly({
      client,
      smcSafeMultisigWallet,
      name: "TestProposalFactory",
      tonPackage: pkgTestProposalFactory,
      input: {
        addrSmvRoot: smcSmvRoot.address,
      },
    });

    smcSmvRootStore = await deployDirectly({
      client,
      smcSafeMultisigWallet,
      name: "SmvRootStore",
      tonPackage: pkgSmvRootStore,
    });

    await smcSmvRootStore.call({
      functionName: "setProposalCode",
      input: await client.boc.get_code_from_tvc({ tvc: pkgProposal.image }),
    });

    await smcSmvRootStore.call({
      functionName: "setPadawanCode",
      input: await client.boc.get_code_from_tvc({ tvc: pkgPadawan.image }),
    });

    await smcSmvRootStore.call({
      functionName: "setProposalFactoryAddr",
      input: { addr: smcTestProposalFactory.address },
    });

    await sendThroughMultisig({
      smcSafeMultisigWallet,
      dest: smcSmvRoot.address,
      value: 5_000_000_000,
    });
    await smcSmvRoot.deploy({
      input: { addrSmvStore: smcSmvRootStore.address },
    });

    await callThroughMultisig({
      client,
      smcSafeMultisigWallet,
      abi: pkgSmvRoot.abi,
      functionName: "deployPadawan",
      input: {
        addrOwner: smcSafeMultisigWallet.address,
      },
      dest: smcSmvRoot.address,
      value: 3_200_000_000,
    });

    smcPadawan = new TonContract({
      client,
      name: "Padawan",
      tonPackage: pkgPadawan,
      address: (
        await smcSmvRoot.run({
          functionName: "resolvePadawan",
          input: {
            addrOwner: smcSafeMultisigWallet.address,
            addrRoot: smcSmvRoot.address,
          },
        })
      ).value.addrPadawan,
    });
  });

  it("deploy Proposal through ProposalFactory", async () => {
    await callThroughMultisig({
      client,
      smcSafeMultisigWallet,
      abi: pkgTestProposalFactory.abi,
      functionName: "deployProposal",
      input: {
        client: EMPTY_ADDRESS,
        title: utf8ToHex("title"),
        whiteList: [],
        specific: {
          duration: 100,
          description: utf8ToHex("description"),
        },
      },
      dest: smcTestProposalFactory.address,
      value: 3_400_000_000,
    });

    smcProposal = new TonContract({
      client,
      name: "Proposal",
      tonPackage: pkgProposal,
      address: (
        await smcSmvRoot.run({
          functionName: "resolveProposal",
          input: {
            addrRoot: smcSmvRoot.address,
            id: 0,
          },
        })
      ).value.addrProposal,
    });
  });

  it("deposit 10000 votes", async () => {
    await deposit(10000);
  });

  it("vote for Proposal with 10 votes", async () => {
    console.log((await smcProposal.run({ functionName: "_data" })).value._data);
    await callThroughMultisig({
      client,
      smcSafeMultisigWallet,
      abi: pkgPadawan.abi,
      functionName: "vote",
      input: {
        addrProposal: smcProposal.address,
        choice: true,
        votes: 10,
      },
      dest: smcPadawan.address,
      value: 1_500_000_000,
    });
    console.log((await smcProposal.run({ functionName: "_data" })).value._data);
  });

  it("vote for Proposal with 500 votes", async () => {
    console.log((await smcProposal.run({ functionName: "_data" })).value._data);
    console.log(
      (await smcProposal.run({ functionName: "_results" })).value._results
    );
    await callThroughMultisig({
      client,
      smcSafeMultisigWallet,
      abi: pkgPadawan.abi,
      functionName: "vote",
      input: {
        addrProposal: smcProposal.address,
        choice: true,
        votes: 500,
      },
      dest: smcPadawan.address,
      value: 1_500_000_000,
    });
    console.log((await smcProposal.run({ functionName: "_data" })).value._data);
    console.log(
      (await smcProposal.run({ functionName: "_results" })).value._results
    );
  });

  it("deploy Proposal2 through ProposalFactory", async () => {
    await callThroughMultisig({
      client,
      smcSafeMultisigWallet,
      abi: pkgTestProposalFactory.abi,
      functionName: "deployProposal",
      input: {
        client: EMPTY_ADDRESS,
        title: utf8ToHex("title"),
        whiteList: [],
        specific: {
          duration: 100,
          description: utf8ToHex("description"),
        },
      },
      dest: smcTestProposalFactory.address,
      value: 3_400_000_000,
    });

    smcProposal2 = new TonContract({
      client,
      name: "Proposal",
      tonPackage: pkgProposal,
      address: (
        await smcSmvRoot.run({
          functionName: "resolveProposal",
          input: {
            addrRoot: smcSmvRoot.address,
            id: 1,
          },
        })
      ).value.addrProposal,
    });
  });

  it("vote against Proposal2 with 510 votes", async () => {
    console.log(
      (await smcProposal2.run({ functionName: "_data" })).value._data
    );
    console.log(
      (await smcProposal2.run({ functionName: "_results" })).value._results
    );
    await callThroughMultisig({
      client,
      smcSafeMultisigWallet,
      abi: pkgPadawan.abi,
      functionName: "vote",
      input: {
        addrProposal: smcProposal2.address,
        choice: false,
        votes: 510,
      },
      dest: smcPadawan.address,
      value: 1_500_000_000,
    });
    console.log(
      (await smcProposal2.run({ functionName: "_data" })).value._data
    );
    console.log(
      (await smcProposal2.run({ functionName: "_results" })).value._results
    );
  });

  it("reclaim", async () => {
    const getPadawanData = async () => {
      const totalVotes = (await smcPadawan.run({ functionName: "_totalVotes" }))
        .value._totalVotes;
      const requestedVotes = (
        await smcPadawan.run({ functionName: "_requestedVotes" })
      ).value._requestedVotes;
      const lockedVotes = (
        await smcPadawan.run({ functionName: "_lockedVotes" })
      ).value._lockedVotes;
      const proposals = (await smcPadawan.run({ functionName: "_proposals" }))
        .value._proposals;
      return {
        totalVotes,
        requestedVotes,
        lockedVotes,
        proposals,
      };
    };
    const {
      totalVotes: totalVotesBefore,
      lockedVotes: lockedVotesBefore,
      requestedVotes: requestedVotesBefore,
      proposals: proposalsBefore,
    } = await getPadawanData();

    await callThroughMultisig({
      client,
      smcSafeMultisigWallet,
      abi: smcPadawan.tonPackage.abi,
      functionName: "updateLockedVotes",
      input: {},
      dest: smcPadawan.address,
      value: 1_000_000_000,
    });

    await callThroughMultisig({
      client,
      smcSafeMultisigWallet,
      abi: smcPadawan.tonPackage.abi,
      functionName: "reclaim",
      input: {
        votes: 10000,
        returnTo: smcSafeMultisigWallet.address,
      },
      dest: smcPadawan.address,
      value: 1_000_000_000,
    });

    console.log(smcPadawan.address);

    const {
      totalVotes: totalVotesAfter,
      lockedVotes: lockedVotesAfter,
      requestedVotes: requestedVotesAfter,
      proposals: proposalsAfter,
    } = await getPadawanData();

    console.log({
      totalVotesBefore,
      lockedVotesBefore,
      proposalsBefore,
      totalVotesAfter,
      lockedVotesAfter,
      proposalsAfter,
      requestedVotesAfter,
      requestedVotesBefore,
    });
  });
});
