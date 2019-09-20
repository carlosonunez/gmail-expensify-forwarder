require 'spec_helper'

# TODO: The right way to do this would be to mock a Gmail account and
# Gmail endpoint and have this script search that instead. However,
# I have _zero_ idea of how to set that up and almost zero minutes
# to spend on figuring that out, so this will suffice for now.
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
        ENV['EMAIL_SENDER'])

    expected_email = read_test_file('expected_quoted_printable_email.html')
    expect(receipt_email.raw).to eq expected_email
  end
end
