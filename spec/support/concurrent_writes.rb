require "timeout"

module ConcurrentWrites
  # 先行トランザクションを開いたまま、別接続が保存を完了するかロックを待つまで進める。
  def race(first_write, &second_write)
    worker = nil
    backend = Queue.new
    ApplicationRecord.transaction do
      first_write.call
      worker = Thread.new do
        ApplicationRecord.connection_pool.with_connection do |connection|
          backend << connection.select_value("SELECT pg_backend_pid()")
          second_write.call
        end
      end
      Timeout.timeout(10) do
        pid = backend.pop
        while worker.alive? && !ApplicationRecord.connection.select_value("SELECT pg_backend_pid() = ANY(pg_blocking_pids(#{Integer(pid)}))")
          sleep 0.01
        end
      end
    end
    worker.value
  ensure
    worker&.join
  end
end
