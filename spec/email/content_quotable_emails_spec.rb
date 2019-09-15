require 'spec_helper'

describe 'Weird email edge cases' do
  it 'Should preserve content if email Content-Type is quoted-printable' do
    mock_gmail_message = OpenStruct.new({
      :id => 0,
      :raw => read_test_file('sample_quoted_printable_email.html')
    })
    receipt_email =
      Forwarder::Receipts::Search.substitute_recipient_to_expensify_address(
        mock_gmail_message,
        'receipts@expensify.com',
        'yeah@boi.null')
    expect(receipt_email.raw).to eq(read_test_file('expected_quoted_printable_email.html'))
  end
end
