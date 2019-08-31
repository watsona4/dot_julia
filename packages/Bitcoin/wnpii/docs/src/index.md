# Bitcoin.jl Documentation

A Bitcoin library for Julia

## Functions

### Address

```@docs
h160_2_address
address
wif
```

### Transaction

```@docs
Bitcoin.txfetch
Bitcoin.txparse
Bitcoin.txserialize
Bitcoin.txhash
Bitcoin.txid
Bitcoin.txfee
Bitcoin.txsighash256
Bitcoin.txsighash
Bitcoin.txinputverify
Bitcoin.txverify
Bitcoin.txsigninput
Bitcoin.txpushsignature
Bitcoin.iscoinbase
Bitcoin.coinbase_height
```

#### Inbound Transaction

```@docs
Bitcoin.txinparse
Bitcoin.txinserialize
Bitcoin.txinvalue
Bitcoin.txin_scriptpubkey
```

#### Outband Transaction

```@docs
Bitcoin.txoutparse(s::Base.GenericIOBuffer)
Bitcoin.txoutserialize(tx::TxOut)
```

### Script

```@docs
Bitcoin.scriptparse
Bitcoin.scriptevaluate
Bitcoin.p2pkh_script
Bitcoin.p2sh_script
Bitcoin.is_p2pkh
Bitcoin.is_p2sh
Bitcoin.script2address
```

### OP

```@docs
Bitcoin.op_ripemd160
Bitcoin.op_sha1
Bitcoin.op_sha256
Bitcoin.op_hash160
Bitcoin.op_hash256
Bitcoin.op_checksig
Bitcoin.op_checksigverify
Bitcoin.op_checkmultisig
Bitcoin.op_checkmultisigverify
Bitcoin.op_checklocktimeverify
Bitcoin.op_checksequenceverify
```

### Block

```@docs
Bitcoin.blockparse
Bitcoin.serialize
Bitcoin.hash
Bitcoin.id
Bitcoin.bip9
Bitcoin.bip91
Bitcoin.bip141
Bitcoin.target
Bitcoin.difficulty
Bitcoin.check_pow
```

## Buy me a cup of coffee

[Donate Bitcoin](bitcoin:34nvxratCQcQgtbwxMJfkmmxwrxtShTn67)

## Index

```@index
```
