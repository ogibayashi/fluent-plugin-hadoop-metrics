require 'helper'

class HadoopMetricsInputTest < Test::Unit::TestCase
  def setup
    Fluent::Test.setup
  end
  
  def teardown
  end
  
  CONFIG = %[
     tag_prefix hadoop.metrics
     namenode localhost:50070
     datanode localhost:50075
     jobtracker localhost:50030
     tasktracker localhost:50060
     interval 60s
  ]
  
  
  def create_driver(conf=CONFIG,tag='test')
    Fluent::Test::InputTestDriver.new(Fluent::HadoopMetricsInput).configure(conf)
  end
  
  def test_configure
    d = create_driver
    assert_equal "hadoop.metrics", d.instance.tag_prefix
    assert_equal "localhost:50070", d.instance.namenode
    assert_equal "localhost:50075", d.instance.datanode
    assert_equal "localhost:50030", d.instance.jobtracker
    assert_equal "localhost:50060", d.instance.tasktracker
  end
  
  # def test_name
  #   d = create_driver
    
  #   time = Time.parse("2011-01-02 13:14:15 UTC").to_i
  #   Fluent::Engine.now = time
    
  #   d.expect_emit "tag1", time, {"a"=>1}
  #   d.expect_emit "tag2", time, {"a"=>2}
    
  #   d.run do
  #     d.expected_emits.each {|tag,time,record|
  #       do something to input data to plugin					
  #       }
  #     end
  #   end
  # end

end
