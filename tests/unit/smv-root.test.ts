import { TonClient } from "@tonclient/core";
import { createClient, TonContract } from "@rsquad/ton-utils";
import pkgProposal from "../../ton-packages/Proposal.package";
import pkgPadawan from "../../ton-packages/Padawan.package";
import pkgTestProposalFactory from "../../ton-packages/TestProposalFactory.package";
import pkgSmvRootStore from "../../ton-packages/SmvRootStore.package";
import pkgSmvRoot from "../../ton-packages/SmvRoot.package";
import { expect } from "chai";
import { createMultisig, deployDirectly } from "../utils";
import { isAddrActive } from "@rsquad/ton-utils/dist/common";
import {
  callThroughMultisig,
  sendThroughMultisig,
} from "@rsquad/ton-utils/dist/net";
import { EMPTY_ADDRESS } from "@rsquad/ton-utils/dist/constants";
import { utf8ToHex } from "@rsquad/ton-utils/dist/convert";

describe("SmvRoot unit test", () => {
  let client: TonClient;
  let smcSafeMultisigWallet: TonContract;
  let smcSmvRootStore: TonContract;
  let smcTestProposalFactory: TonContract;
  let smcPadawan: TonContract;
  let smcProposal: TonContract;
  let smcSmvRoot: TonContract;

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
  });

  it("deploy SmvRoot", async () => {
    await sendThroughMultisig({
      smcSafeMultisigWallet,
      dest: smcSmvRoot.address,
      value: 5_000_000_000,
    });
    await smcSmvRoot.deploy({
      input: { addrSmvRootStore: smcSmvRootStore.address },
    });

    console.log(`SmvRoot has been deployed: ${smcSmvRoot.address}`);
    expect(await isAddrActive(client, smcSmvRoot.address)).to.be.true;
  });

  describe("Padawans", () => {
    it("deploy Padawan", async () => {
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

      expect(
        await isAddrActive(client, smcPadawan.address),
        `Padawan ${smcPadawan.address} isn't active`
      ).to.be.true;
    });
  });

  describe("Proposals", () => {
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

      expect(
        await isAddrActive(client, smcProposal.address),
        `Proposal ${smcProposal.address} isn't active`
      ).to.be.true;
    });
  });
});
