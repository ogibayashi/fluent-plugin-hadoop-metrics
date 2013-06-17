require 'helper'

# For these tests run successfully, all Hadoop daemons have to be running at localhost.

class HadoopMetricsInputTest < Test::Unit::TestCase
  def setup
    Fluent::Test.setup
  end
  
  def teardown
  end

  def default_config
    %[
     tag_prefix hadoop.metrics
     namenode localhost:50070
     datanode localhost:50075
     jobtracker localhost:50030
     tasktracker localhost:50060
     interval 1s
    ]
  end
  
  def create_driver(conf=default_config,tag='test')
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

  def test_metrics
    d = create_driver
    d.run do 
      sleep 2
    end
    emits = d.emits
    assert_equal(true, emits.length > 0)
    # NameNode
    assert_equal("hadoop.metrics.namenode.info", emits[0][0])
    assert_equal("Hadoop:service=NameNode,name=NameNodeInfo", emits[0][2]["name"])
    assert_equal(true, emits[0][2].has_key?("num_livenodes"))
    assert_equal(true, emits[0][2].has_key?("num_deadnodes"))
    assert_equal({}, emits[0][2]["dead_nodes"])
    assert_equal("hadoop.metrics.namenode.dfs", emits[1][0])
    assert_equal("Hadoop:service=NameNode,name=FSNamesystem", emits[1][2]["name"])

    # DataNode
    assert_equal("hadoop.metrics.datanode.info", emits[2][0])
    assert_equal("Hadoop:service=DataNode,name=DataNodeInfo", emits[2][2]["name"])

    # JobTracker
    assert_equal("hadoop.metrics.jobtracker.info", emits[3][0])
    assert_equal("hadoop:service=JobTracker,name=JobTrackerInfo", emits[3][2]["name"])
    assert_equal(true, emits[3][2].has_key?("num_alive_nodes"))
    assert_equal(true, emits[3][2].has_key?("num_blacklisted_nodes"))

    # TaskTracker
    assert_equal("hadoop.metrics.tasktracker.info", emits[4][0])
    assert_equal("hadoop:service=TaskTracker,name=TaskTrackerInfo", emits[4][2]["name"])
  end
  

  def test_server_down
    # Only TT is up.
    d = create_driver (%[
     tag_prefix hadoop.metrics
     namenode localhost:50071
     datanode localhost:50076
     jobtracker localhost:50031
     tasktracker localhost:50060
     interval 1s
    ])
    d.run do 
      sleep 2
    end
    assert_equal("hadoop.metrics.tasktracker.info", d.emits[0][0])
  end

  def test_flatten_string
    conf = default_config
    conf = conf + %[
      flatten_mode string
    ]
    d = create_driver(conf)
    d.run do 
      sleep 2
    end
    emits = d.emits
    assert_equal("{}", emits[0][2]["dead_nodes"])
  end


  def test_flatten_unnest
    conf = default_config
    conf = conf + %[
      flatten_mode unnest
    ]
    d = create_driver(conf)
    d.run do 
      sleep 2
    end
    emits = d.emits
    assert_equal(true, emits[3][2].has_key?("summary_json.slots.map_slots"))
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
