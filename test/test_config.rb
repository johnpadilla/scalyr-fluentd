require 'helper'

class ConfigTest  < Scalyr::ScalyrOutTest

  def test_default_params
    d = create_driver
    assert_nil( d.instance.session_info, "Default sessionInfo not nil" )
    assert( d.instance.ssl_verify_peer, "Default ssl_verify_peer should be true" )

    #check default buffer limits because they are set outside of the config_set_default
    assert_equal( 100*1024, d.instance.buffer.buffer_chunk_limit, "Buffer chunk limit should be 100k" )
    assert_equal( 1024, d.instance.buffer.buffer_queue_limit, "Buffer queue limit should be 1024" )
  end

  def test_configure_ssl_verify_peer
    d = create_driver CONFIG + 'ssl_verify_peer false'
    assert( !d.instance.ssl_verify_peer, "Config failed to set ssl_verify_peer" )
  end

  def test_configure_ssl_ca_bundle_path
    d = create_driver CONFIG + 'ssl_ca_bundle_path /test/ca-bundle.crt'
    assert_equal( "/test/ca-bundle.crt", d.instance.ssl_ca_bundle_path, "Config failed to set ssl_ca_bundle_path" )
  end

  def test_configure_ssl_verify_depth
    d = create_driver CONFIG + 'ssl_verify_depth 10'
    assert_equal( 10, d.instance.ssl_verify_depth, "Config failed to set ssl_verify_depth" )
  end

  def test_configure_session_info
    d = create_driver CONFIG + 'session_info { "test":"value" }'
    assert_equal( "value", d.instance.session_info["test"], "Config failed to set session info" )
  end
end
