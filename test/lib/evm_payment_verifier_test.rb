require "test_helper"
require "minitest/mock"
require "evm_payment_verifier"

class EvmPaymentVerifierTest < ActiveSupport::TestCase
  TOKEN    = "0x94b008aa00579c1307b0ef2c499ad98a8ce58e58"
  RECEIVER = "0xA73405D59e136f574a2FD690079B240f6fbff0a8"
  AMOUNT   = 10_000_000
  PRODUCT  = 19_327
  ITEM     = 1_019_327

  # ── helpers ──────────────────────────────────────────────────────────────

  def payhub_log(to: RECEIVER, token: TOKEN, amount: AMOUNT, product: PRODUCT, item: ITEM)
    data = [
      "000000000000000000000000" + "1111111111111111111111111111111111111111", # from
      "000000000000000000000000" + to.delete_prefix("0x").downcase,
      "000000000000000000000000" + token.delete_prefix("0x").downcase,
      amount.to_s(16).rjust(64, "0"),
      product.to_s(16).rjust(64, "0"),
      item.to_s(16).rjust(64, "0"),
    ].join

    { "topics" => [EvmPaymentVerifier::PAYHUB_TOPIC], "data" => "0x" + data }
  end

  def transfer_log(to: RECEIVER, token: TOKEN, amount: AMOUNT)
    to_topic = "0x" + "000000000000000000000000" + to.delete_prefix("0x").downcase
    {
      "address" => token.downcase,
      "topics"  => [EvmPaymentVerifier::TRANSFER_TOPIC, "0x" + "0" * 64, to_topic],
      "data"    => "0x" + amount.to_s(16).rjust(64, "0"),
    }
  end

  def stub_receipt(logs:, status: "0x1")
    { "result" => { "status" => status, "logs" => logs } }
  end

  def call(txhash: "0xabc", chain: "op", token: TOKEN, receiver: RECEIVER,
           amount: AMOUNT, product: PRODUCT, item: ITEM)
    EvmPaymentVerifier.verify(
      txhash: txhash, chain: chain,
      token_address: token, receiver_address: receiver,
      amount: amount, product_id: product, item_id: item
    )
  end

  # ── SKIP_TX_VERIFY bypass ─────────────────────────────────────────────

  test "returns success when SKIP_TX_VERIFY is set" do
    with_env("SKIP_TX_VERIFY" => "true") do
      result = call
      assert result.success
    end
  end

  # ── unsupported chain ─────────────────────────────────────────────────

  test "fails for unknown chain" do
    result = call(chain: "solana")
    assert_not result.success
    assert_match "unsupported chain", result.error
  end

  # ── PayHub log matching ───────────────────────────────────────────────

  test "succeeds with matching PayHub log" do
    EvmPaymentVerifier.stub(:build_client, mock_client(stub_receipt(logs: [payhub_log]))) do
      assert call.success
    end
  end

  test "fails when PayHub receiver mismatch" do
    log = payhub_log(to: "0x" + "2" * 40)
    EvmPaymentVerifier.stub(:build_client, mock_client(stub_receipt(logs: [log]))) do
      result = call
      assert_not result.success
      assert_match "no matching payment log", result.error
    end
  end

  test "fails when PayHub token mismatch" do
    log = payhub_log(token: "0x" + "3" * 40)
    EvmPaymentVerifier.stub(:build_client, mock_client(stub_receipt(logs: [log]))) do
      assert_not call.success
    end
  end

  test "fails when PayHub amount too low" do
    log = payhub_log(amount: AMOUNT - 1)
    EvmPaymentVerifier.stub(:build_client, mock_client(stub_receipt(logs: [log]))) do
      assert_not call.success
    end
  end

  test "succeeds when PayHub amount exceeds required (overpayment)" do
    log = payhub_log(amount: AMOUNT + 1)
    EvmPaymentVerifier.stub(:build_client, mock_client(stub_receipt(logs: [log]))) do
      assert call.success
    end
  end

  test "fails when PayHub product_id mismatch" do
    log = payhub_log(product: PRODUCT + 1)
    EvmPaymentVerifier.stub(:build_client, mock_client(stub_receipt(logs: [log]))) do
      assert_not call.success
    end
  end

  test "fails when PayHub item_id mismatch" do
    log = payhub_log(item: ITEM + 1)
    EvmPaymentVerifier.stub(:build_client, mock_client(stub_receipt(logs: [log]))) do
      assert_not call.success
    end
  end

  # ── ERC-20 Transfer fallback ──────────────────────────────────────────

  test "succeeds with matching direct Transfer log" do
    EvmPaymentVerifier.stub(:build_client, mock_client(stub_receipt(logs: [transfer_log]))) do
      assert call.success
    end
  end

  test "fails when Transfer receiver mismatch" do
    log = transfer_log(to: "0x" + "4" * 40)
    EvmPaymentVerifier.stub(:build_client, mock_client(stub_receipt(logs: [log]))) do
      assert_not call.success
    end
  end

  test "fails when Transfer token contract mismatch" do
    log = transfer_log(token: "0x" + "5" * 40)
    EvmPaymentVerifier.stub(:build_client, mock_client(stub_receipt(logs: [log]))) do
      assert_not call.success
    end
  end

  # ── tx-level failures ─────────────────────────────────────────────────

  test "fails when transaction not found" do
    EvmPaymentVerifier.stub(:build_client, mock_client(nil)) do
      result = call
      assert_not result.success
      assert_match "not found", result.error
    end
  end

  test "fails when transaction reverted" do
    receipt = stub_receipt(logs: [payhub_log], status: "0x0")
    EvmPaymentVerifier.stub(:build_client, mock_client(receipt)) do
      result = call
      assert_not result.success
      assert_match "reverted", result.error
    end
  end

  test "returns error result on RPC exception" do
    bad_client = Object.new
    def bad_client.eth_get_transaction_receipt(_); raise "connection refused"; end
    EvmPaymentVerifier.stub(:build_client, bad_client) do
      result = call
      assert_not result.success
      assert_match "rpc error", result.error
    end
  end

  # ── real mainnet log fixture ──────────────────────────────────────────
  # TX 0x91efa6ffed022d25e9dec466d0df118a627ecef8d6630128ba60c8a21393e6e5
  # Ethereum mainnet, block 0x141acb2
  REAL_TOKEN    = "0xdac17f958d2ee523a2206206994597c13d831ec7"  # USDT
  REAL_RECEIVER = "0xb81e2ccad7fd1464e59c0da5598fa1b7373486d4"
  REAL_AMOUNT   = 64_000_000  # 64 USDT (6 decimals)
  REAL_PRODUCT  = 7_894
  REAL_ITEM     = 1_001_022

  REAL_PAYHUB_LOG = {
    "address" => "0xa17da9562a4331669fd2fbb9c607c409ae190957",
    "topics"  => ["0xa191b5461d1af36dc9cddfedef42ee06385e1feda25ff8e8f265d88c909ecf2a"],
    "data"    => "0x" \
      "0000000000000000000000008d286c2b4a09b877781aa500a3eba5a4d14fb7eb" \
      "000000000000000000000000b81e2ccad7fd1464e59c0da5598fa1b7373486d4" \
      "000000000000000000000000dac17f958d2ee523a2206206994597c13d831ec7" \
      "0000000000000000000000000000000000000000000000000000000003d09000" \
      "0000000000000000000000000000000000000000000000000000000000001ed6" \
      "00000000000000000000000000000000000000000000000000000000000f463e"
  }.freeze

  # Two Transfer logs also present in the TX (fee split + receiver)
  REAL_TRANSFER_TO_RECEIVER = {
    "address" => REAL_TOKEN,
    "topics"  => [
      EvmPaymentVerifier::TRANSFER_TOPIC,
      "0x0000000000000000000000008d286c2b4a09b877781aa500a3eba5a4d14fb7eb",
      "0x000000000000000000000000b81e2ccad7fd1464e59c0da5598fa1b7373486d4"
    ],
    "data" => "0x0000000000000000000000000000000000000000000000000000000003bd0800"
  }.freeze

  test "verifies real PayHub log from mainnet TX" do
    receipt = stub_receipt(logs: [REAL_PAYHUB_LOG])
    EvmPaymentVerifier.stub(:build_client, mock_client(receipt)) do
      result = EvmPaymentVerifier.verify(
        txhash:           "0x91efa6ffed022d25e9dec466d0df118a627ecef8d6630128ba60c8a21393e6e5",
        chain:            "ethereum",
        token_address:    REAL_TOKEN,
        receiver_address: REAL_RECEIVER,
        amount:           REAL_AMOUNT,
        product_id:       REAL_PRODUCT,
        item_id:          REAL_ITEM
      )
      assert result.success, result.error
    end
  end

  test "verifies real Transfer log from mainnet TX (fallback path)" do
    receipt = stub_receipt(logs: [REAL_TRANSFER_TO_RECEIVER])
    EvmPaymentVerifier.stub(:build_client, mock_client(receipt)) do
      result = EvmPaymentVerifier.verify(
        txhash:           "0x91efa6ffed022d25e9dec466d0df118a627ecef8d6630128ba60c8a21393e6e5",
        chain:            "ethereum",
        token_address:    REAL_TOKEN,
        receiver_address: REAL_RECEIVER,
        amount:           0x3bd0800,  # 62_916_608 — the actual fee-split amount going to receiver
        product_id:       REAL_PRODUCT,
        item_id:          REAL_ITEM
      )
      assert result.success, result.error
    end
  end

  test "rejects real PayHub log when product_id wrong" do
    receipt = stub_receipt(logs: [REAL_PAYHUB_LOG])
    EvmPaymentVerifier.stub(:build_client, mock_client(receipt)) do
      result = EvmPaymentVerifier.verify(
        txhash:           "0x91efa6ffed022d25e9dec466d0df118a627ecef8d6630128ba60c8a21393e6e5",
        chain:            "ethereum",
        token_address:    REAL_TOKEN,
        receiver_address: REAL_RECEIVER,
        amount:           REAL_AMOUNT,
        product_id:       REAL_PRODUCT + 1,
        item_id:          REAL_ITEM
      )
      assert_not result.success
    end
  end

  test "rejects real PayHub log when item_id wrong" do
    receipt = stub_receipt(logs: [REAL_PAYHUB_LOG])
    EvmPaymentVerifier.stub(:build_client, mock_client(receipt)) do
      result = EvmPaymentVerifier.verify(
        txhash:           "0x91efa6ffed022d25e9dec466d0df118a627ecef8d6630128ba60c8a21393e6e5",
        chain:            "ethereum",
        token_address:    REAL_TOKEN,
        receiver_address: REAL_RECEIVER,
        amount:           REAL_AMOUNT,
        product_id:       REAL_PRODUCT,
        item_id:          REAL_ITEM + 1
      )
      assert_not result.success
    end
  end

  private

  def mock_client(receipt)
    client = Object.new
    client.define_singleton_method(:eth_get_transaction_receipt) { |_| receipt }
    client
  end

  def with_env(vars)
    old = vars.to_h { |k, _| [k, ENV[k]] }
    vars.each { |k, v| ENV[k] = v }
    yield
  ensure
    old.each { |k, v| v.nil? ? ENV.delete(k) : ENV[k] = v }
  end
end
