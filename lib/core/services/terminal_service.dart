// Terminal placeholder: real interactive terminal requires native/web integration (eg. webview/webcontainer)
class TerminalService {
  Future<String> runCommand(String cmd) async {
    await Future.delayed(Duration(milliseconds: 400));
    return 'Output (placeholder) for: $cmd';
  }
}
