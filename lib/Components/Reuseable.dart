import 'package:agua_med/theme.dart';
import 'package:floating_action_bubble/floating_action_bubble.dart';
import 'package:flutter/material.dart';

//Custom Button===========================
class Button extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final double? width;
  final double? height;
  final double? borderRadius;
  final Color? color;
  final double? fontSize;
  final Color? textColor;
  final Color? border;

  const Button({
    super.key,
    required this.text,
    required this.onPressed,
    this.width,
    this.height,
    this.color,
    this.fontSize,
    this.textColor,
    this.border,
    double? borderRadius,
  }) : borderRadius = borderRadius ?? 100.0;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onPressed,
        child: Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            border: Border.all(
              color: border ?? transparentColor,
            ),
            color: color ?? primaryColor,
            borderRadius:
                BorderRadius.circular(borderRadius!), // Rounded corners
          ),
          child: Center(
            child: Text(
              text,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: fontSize ?? 14,
                color: textColor ?? whiteColor, // Button text color
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class backButton extends StatelessWidget {
  final double? padding;
  const backButton({super.key, this.padding});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.pop(context),
      child: Container(
        margin: EdgeInsets.only(left: padding ?? p),
        height: 40,
        width: 40,
        decoration: BoxDecoration(shape: BoxShape.circle, color: primaryColor),
        child: Icon(Icons.arrow_back, color: whiteColor),
      ),
    );
  }
}

//Custom AppBar===========================
class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final bool showAction;
  final IconData? icon;
  final VoidCallback? onTap;
  final bool showButton;

  const CustomAppBar(
      {super.key,
      required this.title,
      this.showAction = true,
      this.showButton = true,
      this.icon,
      this.onTap});

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: primaryColor,
      title: Text(title),
      automaticallyImplyLeading: showButton,
      actions: showAction
          ? [
              Padding(
                  padding: EdgeInsets.only(right: p),
                  child: GestureDetector(
                      onTap: onTap, child: Icon(icon, color: whiteColor))),
            ]
          : null,
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(60);
}

//Drawer Tiles======================================

class DrawerTiles extends StatelessWidget {
  final IconData? icon;
  final String? imagePath;
  final String text;
  final VoidCallback onTap;
  final double? size;
  final double? rowWidth;
  final double? padding;
  final bool? selected;

  const DrawerTiles({
    super.key,
    this.icon,
    this.imagePath,
    required this.text,
    required this.onTap,
    this.size,
    this.rowWidth,
    this.padding,
    this.selected,
  });

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.only(right: p, left: p, top: 25),
          color: whiteColor,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  if (icon != null)
                    Padding(
                      padding: EdgeInsets.only(left: padding ?? 0),
                      child: Icon(
                        icon,
                        size: size,
                        color: selected! ? primaryColor : borderColor,
                      ),
                    )
                  else if (imagePath != null)
                    Padding(
                      padding: EdgeInsets.only(left: padding ?? 0),
                      child: Image.asset(
                        imagePath!,
                        width: size,
                        color: selected! ? primaryColor : borderColor,
                      ),
                    ),
                  SizedBox(width: rowWidth),
                  Text(
                    text,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: selected! ? primaryColor : borderColor,
                    ),
                  ),
                ],
              ),
              Container(),
              Icon(Icons.arrow_forward_ios_outlined,
                  size: 18, color: selected! ? primaryColor : borderColor),
            ],
          ),
        ),
      ),
    );
  }
}

//Admin Menu============================================

class AdminMenu extends StatelessWidget {
  final String? image;
  final String text;
  final double height;
  final double size;
  final VoidCallback onTap;
  final IconData? icon;
  const AdminMenu({
    super.key,
    this.image,
    required this.text,
    required this.height,
    required this.size,
    required this.onTap,
    this.icon,
  });
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 120,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(radius),
          color: secondaryColor,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            if (image != null)
              Image.asset(
                image!,
                width: size,
                color: whiteColor,
              )
            else if (icon != null)
              Icon(
                icon,
                size: size,
                color: whiteColor,
              ),
            SizedBox(height: height),
            Text(
              text,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: whiteColor,
              ),
            )
          ],
        ),
      ),
    );
  }
}

//Admin CustomAppBar=======================================
class AdminAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final bool showButton;
  const AdminAppBar({super.key, required this.title, this.showButton = true});

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: primaryColor,
      title: Text(title),
      leading: showButton
          ? GestureDetector(
              onTap: () =>
                  Navigator.pushReplacementNamed(context, '/adminHome'),
              child: Icon(
                Icons.arrow_back_outlined,
                color: whiteColor,
              ))
          : null,
      automaticallyImplyLeading: showButton,
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(60);
}

//Floating Action Button=============================================
class CustomFloatingActionButton extends StatefulWidget {
  final List<Bubble> actions;
  final IconData iconData;

  const CustomFloatingActionButton({
    super.key,
    required this.actions,
    this.iconData = Icons.add,
  });

  @override
  _CustomFloatingActionButtonState createState() =>
      _CustomFloatingActionButtonState();
}

class _CustomFloatingActionButtonState extends State<CustomFloatingActionButton>
    with SingleTickerProviderStateMixin {
  Animation<double>? _animation;
  AnimationController? _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 260),
    );

    final curvedAnimation =
        CurvedAnimation(curve: Curves.easeInOut, parent: _animationController!);
    _animation = Tween<double>(begin: 0, end: 1).animate(curvedAnimation);
  }

  @override
  void dispose() {
    _animationController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FloatingActionBubble(
      animation: _animation!,
      onPress: () => _animationController!.isCompleted
          ? _animationController!.reverse()
          : _animationController!.forward(),
      iconData: widget.iconData,
      iconColor: whiteColor,
      backGroundColor: primaryColor,
      items: widget.actions,
    );
  }
}

// import 'package:flutter/material.dart';
class WebHeader extends StatelessWidget {
  final String title;
  final int index;
  final int selectedIndex;
  final VoidCallback onTap;
  final Color selectedColor;
  final Color unselectedColor;
  final Color selectedTextColor;
  final Color unselectedTextColor;

  const WebHeader({
    super.key,
    required this.title,
    required this.index,
    required this.selectedIndex,
    required this.onTap,
    this.selectedColor = const Color(0xff197ba9),
    this.unselectedColor = Colors.transparent,
    this.selectedTextColor = Colors.white,
    this.unselectedTextColor = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 35,
          width: 85,
          margin: const EdgeInsets.symmetric(horizontal: 5),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(100),
            border: Border.all(
              color: selectedIndex == index
                  ? Colors.transparent
                  : unselectedTextColor,
            ),
            color: selectedIndex == index ? selectedColor : unselectedColor,
          ),
          child: Center(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 14,
                color: selectedIndex == index
                    ? selectedTextColor
                    : unselectedTextColor,
                fontWeight:
                    selectedIndex == index ? FontWeight.bold : FontWeight.w400,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// Admin dashboard ===================================
class AdminDashBoard extends StatelessWidget {
  final String text;
  final String image;
  final String total;
  final double? size;
  final VoidCallback onTap;
  const AdminDashBoard({
    super.key,
    required this.text,
    required this.image,
    required this.total,
    this.size,
    required this.onTap,
  });
  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: Row(
          children: [
            Container(
              height: 78,
              width: 10,
              decoration: BoxDecoration(
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(radius),
                    bottomLeft: Radius.circular(radius),
                  ),
                  color: secondaryColor),
            ),
            Container(
              height: 78,
              width: 225,
              decoration: BoxDecoration(
                color: greyColor,
                borderRadius: BorderRadius.only(
                  topRight: Radius.circular(radius),
                  bottomRight: Radius.circular(radius),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              text,
                              style: TextStyle(
                                fontSize: 14,
                                color: darkGreyColor,
                              ),
                            ),
                            const SizedBox(
                              height: 8,
                            ),
                            Text(
                              total,
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 24,
                                  color: darkGreyColor,
                                  height: 1),
                            ),
                          ],
                        ),
                        Container(
                          height: 30,
                          width: 30,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: secondaryColor,
                          ),
                          child: Center(
                              child: Image.asset(
                            image,
                            width: size ?? 20,
                            color: whiteColor,
                            fit: BoxFit.cover,
                          )),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
