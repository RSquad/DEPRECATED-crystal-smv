import tonos_ts4.ts4 as ts4

eq = ts4.eq

ts4.init("../build/", verbose=True)

SmvRootStore = ts4.BaseContract("SmvRootStore", {})

codeProposal = ts4.load_code_cell("Proposal")
codePadawan = ts4.load_code_cell("Padawan")
addrProposalFactory = ts4.Address(
    "0:c4a31362f0dd98a8cc9282c2f19358c888dfce460d93adb395fa138d61ae5069"
)

codes = dict = {0: codeProposal, 1: codePadawan}
addrs = dict = {0: addrProposalFactory}

SmvRootStore.call_method("setProposalCode", {"code": codeProposal})
SmvRootStore.call_method("setPadawanCode", {"code": codePadawan})
SmvRootStore.call_method("setProposalFactoryAddr", {"addr": addrProposalFactory})

assert ts4.eq(codes, SmvRootStore.call_getter("_codes"))
assert ts4.eq(addrs, SmvRootStore.call_getter("_addrs"))
