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
      end
      if @datanode
        host, port = @datanode.split(':')
        @dn = HadoopMetrics::DataNode.new(host,port)
      end
      if @jobtracker
        host, port = @jobtracker.split(':')
        @jt = HadoopMetrics::JobTracker.new(host,port)
      end
      if @tasktracker
        host, port = @tasktracker.split(':')
        @tt = HadoopMetrics::TaskTracker.new(host,port)
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
      get_nn
    end

    def get_nn
      nninfo = @nn.info
      nninfo['num_livenodes'] = nninfo['live_nodes'].length
      nninfo['num_deadnodes'] = nninfo['dead_nodes'].length
      emit_json([@tag_prefix,"namenode.info"].join("."),Time.now.to_i,nninfo)
    end
    
    def emit_json(tag,time,record)
      Fluent::Engine.emit(tag,time,record.delete_if{ |k,v| v.class==Hash || v.class==Array})
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
