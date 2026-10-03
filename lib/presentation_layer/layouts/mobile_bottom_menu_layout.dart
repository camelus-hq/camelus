import 'package:material_ui/material_ui.dart';
import 'package:go_router/go_router.dart';

const showOnRoutes = ['/home', '/search', '/notifications', '/messages'];

class MobileBottomMenuLayout extends StatelessWidget {
  final Widget mainContent;
  final Widget bottomNavigationBar;

  const MobileBottomMenuLayout({
    super.key,
    required this.mainContent,
    required this.bottomNavigationBar,
  });

  @override
  Widget build(BuildContext context) {
    final currentRoute = GoRouterState.of(context).uri.toString();
    final shouldShow = showOnRoutes.contains(currentRoute);

    return SafeArea(
      top: false,
      bottom: false,
      child: Scaffold(
        resizeToAvoidBottomInset: !currentRoute.startsWith('/map'),
        body: mainContent,
        bottomNavigationBar: AnimatedSwitcher(
          duration: Duration(milliseconds: 250),
          child: shouldShow ? bottomNavigationBar : SizedBox.shrink(),
        ),
      ),
    );
  }
}
