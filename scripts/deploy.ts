// const a = async () => {
//   console.log(123);
// };

import { createClient, TonContract } from "@rsquad/ton-utils";
import pkgProposal from "../ton-packages/Proposal.package";
import pkgPadawan from "../ton-packages/Padawan.package";
import pkgTestProposalFactory from "../ton-packages/TestProposalFactory.package";
import pkgComment from "../ton-packages/Comment.package";
import pkgSmvRootStore from "../ton-packages/SmvRootStore.package";
import pkgSmvRoot from "../ton-packages/SmvRoot.package";
import { createMultisig, deployDirectly } from "../tests/utils";
import { sendThroughMultisig } from "@rsquad/ton-utils/dist/net";
import { utf8ToHex } from "@rsquad/ton-utils/dist/convert";
import { exit } from "process";

(async () => {
  let client;
  let smcSafeMultisigWallet;
  let smcSmvRootStore;
  let smcTestProposalFactory;
  let smcSmvRoot;
  client = createClient();
  smcSafeMultisigWallet = createMultisig(client);

  smcSmvRoot = new TonContract({
    client,
    name: "SmvRoot",
    tonPackage: pkgSmvRoot,
    keys: await client.crypto.generate_random_sign_keys(),
  });

  await smcSmvRoot.calcAddress();
  console.log(`SmvRoot address: ${smcSmvRoot.address}`);

  console.log(`Deploying TestProposalFactory`);
  smcTestProposalFactory = await deployDirectly({
    client,
    smcSafeMultisigWallet,
    name: "TestProposalFactory",
    tonPackage: pkgTestProposalFactory,
    input: {
      addrSmvRoot: smcSmvRoot.address,
    },
  });
  console.log(
    `TestProposalFactory has been deployed: ${smcTestProposalFactory.address}`
  );

  console.log(`Deploying SmvRootStore`);
  smcSmvRootStore = await deployDirectly({
    client,
    smcSafeMultisigWallet,
    name: "SmvRootStore",
    tonPackage: pkgSmvRootStore,
  });
  console.log(`SmvRootStore has been deployed: ${smcSmvRootStore.address}`);

  console.log(`Setting Proposal code`);
  await smcSmvRootStore.call({
    functionName: "setProposalCode",
    input: await client.boc.get_code_from_tvc({ tvc: pkgProposal.image }),
  });

  console.log(`Setting Padawan code`);
  await smcSmvRootStore.call({
    functionName: "setPadawanCode",
    input: await client.boc.get_code_from_tvc({ tvc: pkgPadawan.image }),
  });

  console.log(`Setting Comment code`);
  await smcSmvRootStore.call({
    functionName: "setCommentCode",
    input: await client.boc.get_code_from_tvc({ tvc: pkgComment.image }),
  });

  console.log(`Setting ProposalFactory address`);
  await smcSmvRootStore.call({
    functionName: "setProposalFactoryAddr",
    input: { addr: smcTestProposalFactory.address },
  });

  console.log(`Setting ProposalFactory abi`);
  await smcSmvRootStore.call({
    functionName: "setProposalFactoryAbi",
    input: {
      strAbi: utf8ToHex(JSON.stringify(smcTestProposalFactory.tonPackage.abi)),
    },
  });

  console.log(`Deploying SmvRoot`);
  await sendThroughMultisig({
    smcSafeMultisigWallet,
    dest: smcSmvRoot.address,
    value: 5_000_000_000,
  });

  await smcSmvRoot.deploy({
    input: {
      addrSmvStore: smcSmvRootStore.address,
      title: utf8ToHex("Example governance SMV"),
    },
  });

  console.log(`SmvRoot has been deployed: ${smcSmvRoot.address}`);

  exit();
})();
