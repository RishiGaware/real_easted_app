import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:inhabit_realties/constants/contants.dart';

class AnimatedSearchBar extends StatefulWidget {
  const AnimatedSearchBar({super.key});

  @override
  State<AnimatedSearchBar> createState() => _AnimatedSearchBarState();
}

class _AnimatedSearchBarState extends State<AnimatedSearchBar> {
   bool _isSearchActive = false;
  final _focusNode = FocusNode();

  void _toggleSearch() {
    setState(() {
      _isSearchActive = !_isSearchActive;
    });
    if (!_isSearchActive) {
      _focusNode.unfocus();
    }
  }
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? AppColors.darkCardBackground : AppColors.lightCardBackground;
    final textColor = isDark ? AppColors.darkWhiteText : AppColors.lightDarkText;
    final searchBarColor = isDark ? AppColors.lightDarkText : AppColors.darkWhiteText;
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final shadowColor = isDark ?AppColors.lightCardBackground :AppColors.darkCardBackground;
    return Padding(
      padding: const EdgeInsets.only(left: 10, right: 20),
      child: GestureDetector(
        onTap: _toggleSearch,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: _isSearchActive ? screenWidth*0.40 : screenWidth/10,
          height: 40,
          decoration: BoxDecoration(
            color: searchBarColor,
            borderRadius: BorderRadius.circular(50),
            boxShadow: [
                              BoxShadow(
                                blurRadius: 0.01,
                                spreadRadius: 2,
                                offset: const Offset(0, 0),
                                color: shadowColor.withOpacity(0.1)
                              )
                            ]
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Padding(
                padding: EdgeInsets.only(left: _isSearchActive ? 10 : 0),
                child: Icon(CupertinoIcons.search, color: textColor),
              ),
              _isSearchActive ? Expanded(child: Padding(
                padding: const EdgeInsets.only(right: 10),
                child: TextField(
                  autofocus: true,
                  focusNode: _focusNode,
                  style: TextStyle(color: textColor),
                  enableInteractiveSelection: true,
                  contextMenuBuilder: (context, editableTextState) {
                    return AdaptiveTextSelectionToolbar.editableText(
                      editableTextState: editableTextState,
                    );
                  },
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    hintText: "Type to search...",
                    hintStyle: TextStyle(color: textColor),
                  ),
                ),
              )) : Container(),
            ],
          ),
        ),
      ),
    );
  }
}