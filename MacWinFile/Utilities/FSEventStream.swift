import Foundation

class DirectoryWatcher {
    private var stream: FSEventStreamRef?
    private let path: String
    private let callback: () -> Void
    private let debounceInterval: TimeInterval = 0.3
    private var debounceTimer: Timer?
    private var isRunning = false

    init(path: String, callback: @escaping () -> Void) {
        self.path = path
        self.callback = callback
    }

    deinit {
        stop()
    }

    func start() {
        guard !isRunning else { return }
        let paths = [path] as CFArray

        // Use a pointer to a flag that we control, not to self
        let info = Unmanaged.passRetained(CallbackBox(watcher: self)).toOpaque()

        var context = FSEventStreamContext()
        context.info = info
        context.release = { ptr in
            guard let ptr else { return }
            Unmanaged<CallbackBox>.fromOpaque(ptr).release()
        }

        stream = FSEventStreamCreate(
            nil,
            { (_, info, _, _, _, _) in
                guard let info else { return }
                let box = Unmanaged<CallbackBox>.fromOpaque(info).takeUnretainedValue()
                box.watcher?.handleEvents()
            },
            &context,
            paths,
            FSEventStreamEventId(kFSEventStreamEventIdSinceNow),
            0.5,
            FSEventStreamCreateFlags(kFSEventStreamCreateFlagUseCFTypes | kFSEventStreamCreateFlagFileEvents)
        )

        guard let stream else { return }
        FSEventStreamSetDispatchQueue(stream, DispatchQueue.main)
        FSEventStreamStart(stream)
        isRunning = true
    }

    func stop() {
        debounceTimer?.invalidate()
        debounceTimer = nil
        guard let stream, isRunning else { return }
        FSEventStreamStop(stream)
        FSEventStreamInvalidate(stream)
        FSEventStreamRelease(stream)
        self.stream = nil
        isRunning = false
    }

    private func handleEvents() {
        debounceTimer?.invalidate()
        debounceTimer = Timer.scheduledTimer(withTimeInterval: debounceInterval, repeats: false) { [weak self] _ in
            self?.callback()
        }
    }
}

// prevent dangling pointer — weak reference to watcher
private class CallbackBox {
    weak var watcher: DirectoryWatcher?
    init(watcher: DirectoryWatcher) { self.watcher = watcher }
}
