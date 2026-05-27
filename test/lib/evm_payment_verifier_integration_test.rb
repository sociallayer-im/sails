require "test_helper"
require "evm_payment_verifier"

# Live integration test against Alchemy — uses real mainnet data.
# Skipped unless ALCHEMY_API_KEY is set and LIVE_TEST=1.
#
# TX: 0x91efa6ffed022d25e9dec466d0df118a627ecef8d6630128ba60c8a21393e6e5
# Chain: ethereum (block 0x141acb2)
# PayHub contract: 0xa17DA9562a4331669Fd2FBb9c607c409Ae190957
# Token (USDT):    0xdac17f958d2ee523a2206206994597c13d831ec7
# Receiver:        0xb81e2ccad7fd1464e59c0da5598fa1b7373486d4
# Amount:          64_000_000 (64 USDT, 6 decimals)
# product_id:      7_894
# item_id:         1_001_022
class EvmPaymentVerifierIntegrationTest < ActiveSupport::TestCase
  TXHASH    = "0x91efa6ffed022d25e9dec466d0df118a627ecef8d6630128ba60c8a21393e6e5"
  CHAIN     = "ethereum"
  TOKEN     = "0xdac17f958d2ee523a2206206994597c13d831ec7"
  RECEIVER  = "0xb81e2ccad7fd1464e59c0da5598fa1b7373486d4"
  AMOUNT    = 64_000_000
  PRODUCT   = 7_894
  ITEM      = 1_001_022

  def live?
    ENV["LIVE_TEST"] == "1" && ENV["ALCHEMY_API_KEY"].present?
  end

  test "verifies real PayHub TX against ethereum mainnet" do
    skip "set LIVE_TEST=1 and ALCHEMY_API_KEY to run" unless live?

    result = EvmPaymentVerifier.verify(
      txhash:           TXHASH,
      chain:            CHAIN,
      token_address:    TOKEN,
      receiver_address: RECEIVER,
      amount:           AMOUNT,
      product_id:       PRODUCT,
      item_id:          ITEM
    )

    assert result.success, "Expected success but got: #{result.error}"
    assert_nil result.error
  end

  test "fails when wrong receiver on real TX" do
    skip "set LIVE_TEST=1 and ALCHEMY_API_KEY to run" unless live?

    result = EvmPaymentVerifier.verify(
      txhash:           TXHASH,
      chain:            CHAIN,
      token_address:    TOKEN,
      receiver_address: "0x" + "9" * 40,
      amount:           AMOUNT,
      product_id:       PRODUCT,
      item_id:          ITEM
    )

    assert_not result.success
    assert_match "no matching payment log", result.error
  end

  test "fails when amount exceeds actual TX amount" do
    skip "set LIVE_TEST=1 and ALCHEMY_API_KEY to run" unless live?

    result = EvmPaymentVerifier.verify(
      txhash:           TXHASH,
      chain:            CHAIN,
      token_address:    TOKEN,
      receiver_address: RECEIVER,
      amount:           AMOUNT + 1,
      product_id:       PRODUCT,
      item_id:          ITEM
    )

    assert_not result.success
  end

  test "fails when wrong product_id on real TX" do
    skip "set LIVE_TEST=1 and ALCHEMY_API_KEY to run" unless live?

    result = EvmPaymentVerifier.verify(
      txhash:           TXHASH,
      chain:            CHAIN,
      token_address:    TOKEN,
      receiver_address: RECEIVER,
      amount:           AMOUNT,
      product_id:       PRODUCT + 1,
      item_id:          ITEM
    )

    assert_not result.success
  end

  test "fails when wrong item_id on real TX" do
    skip "set LIVE_TEST=1 and ALCHEMY_API_KEY to run" unless live?

    result = EvmPaymentVerifier.verify(
      txhash:           TXHASH,
      chain:            CHAIN,
      token_address:    TOKEN,
      receiver_address: RECEIVER,
      amount:           AMOUNT,
      product_id:       PRODUCT,
      item_id:          ITEM + 1
    )

    assert_not result.success
  end
end
