require 'ch_digest'

RSpec.describe "CHDigest::Reader column mapping" do
  def csv_content
    CSV.generate {|csv| yield csv}
  end
  
  def read_content(**opts)
    args = [csv_content {|csv| yield csv}]
    
    # Awkward, but compatible with Ruby 2.5+ and 3.0+
    if opts.empty?
      CHDigest::Reader.new(*args)
    else
      CHDigest::Reader.new(*args, **opts)
    end
  end
  
  %w[
    id name created_at started_at completed_at state epic project
    requester owners description
  ].each do |col_name|
    specify "#{col_name.inspect} maps to itself" do
      r = read_content do |csv|
        csv << [col_name]
      end
      expect(r.headers).to be == [col_name]
    end
  end
  
  specify "\"labels\" maps to several columns" do
    r = read_content do |csv|
      csv << ["labels"]
    end
    expect(r.headers).to be == ["Client", "Severity", "agency", "source", "Cause", "layer"]
  end
  
  specify "ordered as directed" do
    r = read_content do |csv|
      csv << %w[name id created_at started_at completed_at epic unspec1 state type labels project unspec2 requester owners description]
    end
    expect(r.headers).to be == %w[id name type Client Severity created_at started_at completed_at state epic project agency source Cause layer requester owners description unspec1 unspec2]
  end
  
  specify "Transferred values copy by mapping" do
    r = read_content do |csv|
      csv << %w[name id type]
      csv << %w[one two three]
    end
    expect(r.headers).to be == %w[id name type]
    expect(r.shift).to be == %w[two one three]
  end
  
  specify "\"labels\" is decomposed as requested" do
    r = read_content do |csv|
      csv << %w[labels created_at id owners]
      csv << ["client: Foo;agency: Bar", "123", "456", "789"]
    end
    expect(r.headers).to be == %w[id Client Severity created_at agency source Cause layer owners]
    expect(r.shift).to be == ['456', 'Foo', nil, '123', 'Bar', nil, nil, nil, '789']
  end
  
  specify "formatting of \"Severity\"" do
    r = read_content do |csv|
      csv << %w[labels]
      (0..5).each do |sev_n|
        csv << ["severity: #{sev_n}"]
      end
    end
    col_idx = r.headers.index('Severity')
    expect(col_idx).to_not be_nil
    expect(r.map {|row| row[col_idx]}).to be == (0..5).map {|sev_n| "SV#{sev_n}"}
  end
  
  specify "omitting description" do
    r = read_content(omitting_values_of: %w[description]) do |csv|
      csv << %w[id name unspec description]
      csv << ['123', 'foo', 'bar', 'baz']
    end
    out_row = r.shift
    expect(out_row).to be == ['123', 'foo', nil, 'bar']
  end
end
