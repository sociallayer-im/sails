#!/usr/bin/env ruby
# frozen_string_literal: true
#
# Standalone live test for EvmPaymentVerifier against real mainnet data.
#
# Usage:
#   ALCHEMY_API_KEY=<key> bin/rails runner script/test_evm_verifier.rb
#   # or from any Ruby env with eth gem:
#   ALCHEMY_API_KEY=<key> ruby -I lib script/test_evm_verifier.rb
#
# TX: 0x91efa6ffed022d25e9dec466d0df118a627ecef8d6630128ba60c8a21393e6e5
# Ethereum mainnet, block 21,151,922 (0x141acb2)

require_relative "../lib/evm_payment_verifier"

TXHASH   = "0x91efa6ffed022d25e9dec466d0df118a627ecef8d6630128ba60c8a21393e6e5"
CHAIN    = "ethereum"
TOKEN    = "0xdac17f958d2ee523a2206206994597c13d831ec7"  # USDT
RECEIVER = "0xb81e2ccad7fd1464e59c0da5598fa1b7373486d4"
AMOUNT   = 64_000_000   # 64 USDT (6 decimals)
PRODUCT  = 7_894        # event_id
ITEM     = 1_001_022    # order_number

CASES = [
  {
    label:   "✓ exact match (should PASS)",
    txhash:  TXHASH, chain: CHAIN,
    token:   TOKEN,   receiver: RECEIVER,
    amount:  AMOUNT,  product: PRODUCT, item: ITEM,
    expect:  true
  },
  {
    label:   "✓ overpayment accepted (should PASS)",
    txhash:  TXHASH, chain: CHAIN,
    token:   TOKEN,   receiver: RECEIVER,
    amount:  AMOUNT - 1_000_000,
    product: PRODUCT, item: ITEM,
    expect:  true
  },
  {
    label:   "✗ wrong receiver (should FAIL)",
    txhash:  TXHASH, chain: CHAIN,
    token:   TOKEN,   receiver: "0x" + "9" * 40,
    amount:  AMOUNT,  product: PRODUCT, item: ITEM,
    expect:  false
  },
  {
    label:   "✗ wrong token (should FAIL)",
    txhash:  TXHASH, chain: CHAIN,
    token:   "0x" + "a" * 40, receiver: RECEIVER,
    amount:  AMOUNT,  product: PRODUCT, item: ITEM,
    expect:  false
  },
  {
    label:   "✗ amount too high (should FAIL)",
    txhash:  TXHASH, chain: CHAIN,
    token:   TOKEN,   receiver: RECEIVER,
    amount:  AMOUNT + 1,
    product: PRODUCT, item: ITEM,
    expect:  false
  },
  {
    label:   "✗ wrong product_id (should FAIL)",
    txhash:  TXHASH, chain: CHAIN,
    token:   TOKEN,   receiver: RECEIVER,
    amount:  AMOUNT,  product: PRODUCT + 1, item: ITEM,
    expect:  false
  },
  {
    label:   "✗ wrong item_id (should FAIL)",
    txhash:  TXHASH, chain: CHAIN,
    token:   TOKEN,   receiver: RECEIVER,
    amount:  AMOUNT,  product: PRODUCT, item: ITEM + 1,
    expect:  false
  },
  {
    label:   "✗ unsupported chain (should FAIL)",
    txhash:  TXHASH, chain: "solana",
    token:   TOKEN,   receiver: RECEIVER,
    amount:  AMOUNT,  product: PRODUCT, item: ITEM,
    expect:  false
  },
].freeze

puts "EvmPaymentVerifier live test — #{CHAIN} TX #{TXHASH[0, 20]}..."
puts "=" * 70
passed = 0
failed = 0

CASES.each_with_index do |c, i|
  result = EvmPaymentVerifier.verify(
    txhash:           c[:txhash],
    chain:            c[:chain],
    token_address:    c[:token],
    receiver_address: c[:receiver],
    amount:           c[:amount],
    product_id:       c[:product],
    item_id:          c[:item]
  )

  ok = result.success == c[:expect]
  status = ok ? "PASS" : "FAIL"
  detail = result.success ? "success" : "error: #{result.error}"
  puts "[#{status}] #{c[:label]}"
  puts "       → #{detail}" unless ok
  ok ? passed += 1 : failed += 1
end

puts "=" * 70
puts "#{passed} passed, #{failed} failed"
exit(failed > 0 ? 1 : 0)
