module Fluent

  class HadoopMetricsInput < Input
    Plugin.register_input('hadoop_metrics', self)

    def initialize
      require 'hadoop_metrics'
      super
      @jt = nil
      @tt = nil
      @nn = nil
      @dn = nil
    end

    config_param :tag_prefix,:string, :default => "hadoop.metrics"
    config_param :namenode,:string, :default => nil
    config_param :datanode,:string, :default => nil
    config_param :jobtracker,:string, :default => nil
    config_param :tasktracker,:string,:default => nil
    config_param :interval, :time, :default =>  60

    def configure(conf)
      super
    end

    def start
      if @namenode
        host, port = @namenode.split(':')
        @nn = HadoopMetrics::NameNode.new(host,port)
        @tag_nninfo = [@tag_prefix,"namenode.info"].join(".")
        @tag_nndfs = [@tag_prefix,"namenode.dfs"].join(".")
      end
      if @datanode
        host, port = @datanode.split(':')
        @dn = HadoopMetrics::DataNode.new(host,port)
        @tag_dninfo = [@tag_prefix,"datanode.info"].join(".")
      end
      if @jobtracker
        host, port = @jobtracker.split(':')
        @jt = HadoopMetrics::JobTracker.new(host,port)
        @tag_jtinfo = [@tag_prefix,"jobtracker.info"].join(".")
      end
      if @tasktracker
        host, port = @tasktracker.split(':')
        @tt = HadoopMetrics::TaskTracker.new(host,port)
        @tag_ttinfo = [@tag_prefix,"tasktracker.info"].join(".")
      end
      @loop = Coolio::Loop.new
      @loop.attach(TimerWatcher.new(@interval, true, &method(:check_metrics)))
      @thread = Thread.new(&method(:run))
    end

    def shutdown
      @loop.stop
      @thread.join
    end

    def run
      @loop.run
    rescue
      $log.error "unexpected error", :error=>$!.to_s
      $log.error_backtrace
    end

    def check_metrics
      get_nn if @nn
      get_dn if @dn
      get_jt if @jt
      get_tt if @tt
    end

    # NameNode
    def get_nn
      begin
        nninfo = @nn.info
        nninfo['num_livenodes'] = nninfo['live_nodes'].length
        nninfo['num_deadnodes'] = nninfo['dead_nodes'].length
        emit_json(@tag_nninfo,Time.now.to_i,nninfo)
        nndfs = @nn.dfs
        emit_json(@tag_nndfs,Time.now.to_i,nndfs)
      rescue Errno::ECONNREFUSED
        $log.warn "NameNode at #{@namenode} is down."
      end
    end

    # DataNode
    def get_dn
      begin
        dninfo = @dn.info
        emit_json(@tag_dninfo,Time.now.to_i,dninfo)
      rescue Errno::ECONNREFUSED
        $log.warn "DataNode at #{@datanode} is down."
      end
    end
    
    # JobTracker
    def get_jt
      begin
        jtinfo = @jt.info
        jtinfo['num_alive_nodes'] = jtinfo['alive_nodes_info_json'].length
        jtinfo['num_blacklisted_nodes'] = jtinfo['blacklisted_nodes_info_json'].length
        emit_json(@tag_jtinfo,Time.now.to_i,jtinfo)
      rescue Errno::ECONNREFUSED
        $log.warn "JobTracker at #{@jobtracker} is down."
      end
    end

    # TaskTracker
    def get_tt
      begin
        ttinfo = @tt.info
        emit_json(@tag_ttinfo,Time.now.to_i,ttinfo)
      rescue Errno::ECONNREFUSED
        $log.warn "TaskTracker at #{@tasktracker} is down."
      end
    end

    # Convert Hash or Array as JSON value to String.
    def emit_json(tag,time,record)
      if record
        Fluent::Engine.emit(tag,time,
                            record.each{ |k,v| 
                              record[k] = (v.class==Hash || v.class==Array) ? v.to_s : v
                            })
      end
    end
    
    class TimerWatcher < Coolio::TimerWatcher
      def initialize(interval, repeat, &callback)
        @callback = callback
        super(interval, repeat)
      end

      def on_timer
        @callback.call
      rescue
        # TODO log?
        $log.error $!.to_s
        $log.error_backtrace
      end
    end

  end
end
