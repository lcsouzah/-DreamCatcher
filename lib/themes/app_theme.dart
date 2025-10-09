import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';

class DreamGradients extends ThemeExtension<DreamGradients> {
  const DreamGradients({
    required this.scaffold,
    required this.wallet,
    required this.settings,
    required this.cardHighlight,
    required this.primaryButton,
    required this.disabledButton,
    required this.badgeKeepGoing,
    required this.badgeFindingRhythm,
    required this.badgeHotStreak,
    required this.badgeLegendary,
  });

  final LinearGradient scaffold;
  final LinearGradient wallet;
  final LinearGradient settings;
  final LinearGradient cardHighlight;
  final LinearGradient primaryButton;
  final LinearGradient disabledButton;
  final LinearGradient badgeKeepGoing;
  final LinearGradient badgeFindingRhythm;
  final LinearGradient badgeHotStreak;
  final LinearGradient badgeLegendary;

  static const DreamGradients fallback = DreamGradients(
    scaffold: LinearGradient(
      colors: <Color>[Color(0xFF05061A), Color(0xFF10163F), Color(0xFF1A1F53)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    wallet: LinearGradient(
      colors: <Color>[Color(0xFF05061A), Color(0xFF141D52), Color(0xFF2B2E7D)],
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
    ),
    settings: LinearGradient(
      colors: <Color>[Color(0xFF080B1F), Color(0xFF1E1743), Color(0xFF352365)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    cardHighlight: LinearGradient(
      colors: <Color>[Color(0x55FFFFFF), Color(0x11FFFFFF)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    primaryButton: LinearGradient(
      colors: <Color>[Color(0xFF8C7BFF), Color(0xFF6E8EF5), Color(0xFF58E1F3)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    disabledButton: LinearGradient(
      colors: <Color>[Color(0x22FFFFFF), Color(0x0DFFFFFF)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    badgeKeepGoing: LinearGradient(
      colors: <Color>[Color(0xFF7B61FF), Color(0xFF4E54C8)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    badgeFindingRhythm: LinearGradient(
      colors: <Color>[Color(0xFF80DEEA), Color(0xFF5E72EB)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    badgeHotStreak: LinearGradient(
      colors: <Color>[Color(0xFFFFD180), Color(0xFFFF8F00)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    badgeLegendary: LinearGradient(
      colors: <Color>[Color(0xFFFF8A80), Color(0xFFFF5F6D)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
  );

  @override
  DreamGradients copyWith({
    LinearGradient? scaffold,
    LinearGradient? wallet,
    LinearGradient? settings,
    LinearGradient? cardHighlight,
    LinearGradient? primaryButton,
    LinearGradient? disabledButton,
    LinearGradient? badgeKeepGoing,
    LinearGradient? badgeFindingRhythm,
    LinearGradient? badgeHotStreak,
    LinearGradient? badgeLegendary,
  }) {
    return DreamGradients(
      scaffold: scaffold ?? this.scaffold,
      wallet: wallet ?? this.wallet,
      settings: settings ?? this.settings,
      cardHighlight: cardHighlight ?? this.cardHighlight,
      primaryButton: primaryButton ?? this.primaryButton,
      disabledButton: disabledButton ?? this.disabledButton,
      badgeKeepGoing: badgeKeepGoing ?? this.badgeKeepGoing,
      badgeFindingRhythm: badgeFindingRhythm ?? this.badgeFindingRhythm,
      badgeHotStreak: badgeHotStreak ?? this.badgeHotStreak,
      badgeLegendary: badgeLegendary ?? this.badgeLegendary,
    );
  }

  @override
  DreamGradients lerp(ThemeExtension<DreamGradients>? other, double t) {
    if (other is! DreamGradients) {
      return this;
    }

    return DreamGradients(
      scaffold: LinearGradient.lerp(scaffold, other.scaffold, t) ?? scaffold,
      wallet: LinearGradient.lerp(wallet, other.wallet, t) ?? wallet,
      settings: LinearGradient.lerp(settings, other.settings, t) ?? settings,
      cardHighlight: LinearGradient.lerp(cardHighlight, other.cardHighlight, t) ?? cardHighlight,
      primaryButton: LinearGradient.lerp(primaryButton, other.primaryButton, t) ?? primaryButton,
      disabledButton: LinearGradient.lerp(disabledButton, other.disabledButton, t) ?? disabledButton,
      badgeKeepGoing:
      LinearGradient.lerp(badgeKeepGoing, other.badgeKeepGoing, t) ?? badgeKeepGoing,
      badgeFindingRhythm:
      LinearGradient.lerp(badgeFindingRhythm, other.badgeFindingRhythm, t) ??
          badgeFindingRhythm,
      badgeHotStreak:
      LinearGradient.lerp(badgeHotStreak, other.badgeHotStreak, t) ?? badgeHotStreak,
      badgeLegendary:
      LinearGradient.lerp(badgeLegendary, other.badgeLegendary, t) ?? badgeLegendary,
    );
  }
}

class DreamCardTheme extends ThemeExtension<DreamCardTheme> {
  const DreamCardTheme({
    required this.backgroundGradient,
    required this.overlayColor,
    required this.borderColor,
    required this.borderRadius,
    required this.shadow,
    required this.blurSigma,
  });

  final LinearGradient backgroundGradient;
  final Color overlayColor;
  final Color borderColor;
  final BorderRadius borderRadius;
  final List<BoxShadow> shadow;
  final double blurSigma;

  static const DreamCardTheme fallback = DreamCardTheme(
    backgroundGradient: LinearGradient(
      colors: <Color>[Color(0x66FFFFFF), Color(0x11FFFFFF)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    overlayColor: Color(0x330D1028),
    borderColor: Color(0x33FFFFFF),
    borderRadius: BorderRadius.all(Radius.circular(24)),
    shadow: <BoxShadow>[
      BoxShadow(
        color: Color(0x66131B46),
        blurRadius: 24,
        offset: Offset(0, 18),
        spreadRadius: -12,
      ),
    ],
    blurSigma: 18,
  );

  @override
  DreamCardTheme copyWith({
    LinearGradient? backgroundGradient,
    Color? overlayColor,
    Color? borderColor,
    BorderRadius? borderRadius,
    List<BoxShadow>? shadow,
    double? blurSigma,
  }) {
    return DreamCardTheme(
      backgroundGradient: backgroundGradient ?? this.backgroundGradient,
      overlayColor: overlayColor ?? this.overlayColor,
      borderColor: borderColor ?? this.borderColor,
      borderRadius: borderRadius ?? this.borderRadius,
      shadow: shadow ?? this.shadow,
      blurSigma: blurSigma ?? this.blurSigma,
    );
  }

  @override
  DreamCardTheme lerp(ThemeExtension<DreamCardTheme>? other, double t) {
    if (other is! DreamCardTheme) {
      return this;
    }

    return DreamCardTheme(
      backgroundGradient:
      LinearGradient.lerp(backgroundGradient, other.backgroundGradient, t) ?? backgroundGradient,
      overlayColor: Color.lerp(overlayColor, other.overlayColor, t) ?? overlayColor,
      borderColor: Color.lerp(borderColor, other.borderColor, t) ?? borderColor,
      borderRadius: BorderRadius.lerp(borderRadius, other.borderRadius, t) ?? borderRadius,
      shadow: BoxShadow.lerpList(shadow, other.shadow, t) ?? shadow,
      blurSigma: lerpDouble(blurSigma, other.blurSigma, t) ?? blurSigma,
    );
  }
}

class DreamButtonTheme extends ThemeExtension<DreamButtonTheme> {
  const DreamButtonTheme({
    required this.foregroundColor,
    required this.primaryGradient,
    required this.disabledGradient,
    required this.borderRadius,
    required this.padding,
    required this.glow,
  });

  final Color foregroundColor;
  final LinearGradient primaryGradient;
  final LinearGradient disabledGradient;
  final BorderRadius borderRadius;
  final EdgeInsets padding;
  final List<BoxShadow> glow;

  static const DreamButtonTheme fallback = DreamButtonTheme(
    foregroundColor: Colors.white,
    primaryGradient: LinearGradient(
      colors: <Color>[Color(0xFF8C7BFF), Color(0xFF6E8EF5), Color(0xFF58E1F3)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    disabledGradient: LinearGradient(
      colors: <Color>[Color(0x22FFFFFF), Color(0x0DFFFFFF)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    borderRadius: BorderRadius.all(Radius.circular(20)),
    padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
    glow: <BoxShadow>[
      BoxShadow(
        color: Color(0x3358E1F3),
        blurRadius: 24,
        spreadRadius: 1,
        offset: Offset(0, 10),
      ),
    ],
  );

  @override
  DreamButtonTheme copyWith({
    Color? foregroundColor,
    LinearGradient? primaryGradient,
    LinearGradient? disabledGradient,
    BorderRadius? borderRadius,
    EdgeInsets? padding,
    List<BoxShadow>? glow,
  }) {
    return DreamButtonTheme(
      foregroundColor: foregroundColor ?? this.foregroundColor,
      primaryGradient: primaryGradient ?? this.primaryGradient,
      disabledGradient: disabledGradient ?? this.disabledGradient,
      borderRadius: borderRadius ?? this.borderRadius,
      padding: padding ?? this.padding,
      glow: glow ?? this.glow,
    );
  }

  @override
  DreamButtonTheme lerp(ThemeExtension<DreamButtonTheme>? other, double t) {
    if (other is! DreamButtonTheme) {
      return this;
    }

    return DreamButtonTheme(
      foregroundColor: Color.lerp(foregroundColor, other.foregroundColor, t) ?? foregroundColor,
      primaryGradient: LinearGradient.lerp(primaryGradient, other.primaryGradient, t) ??
          primaryGradient,
      disabledGradient: LinearGradient.lerp(disabledGradient, other.disabledGradient, t) ??
          disabledGradient,
      borderRadius: BorderRadius.lerp(borderRadius, other.borderRadius, t) ?? borderRadius,
      padding: EdgeInsets.lerp(padding, other.padding, t) ?? padding,
      glow: BoxShadow.lerpList(glow, other.glow, t) ?? glow,
    );
  }
}

class AppTheme {
  AppTheme._();

  static final ThemeData dreamTheme = _buildDreamTheme();

  static ThemeData _buildDreamTheme() {
    const Color primary = Color(0xFF7B61FF);
    const Color secondary = Color(0xFFB76CFF);
    const Color background = Color(0xFF06071A);
    const Color surface = Color(0xFF111537);
    const Color surfaceVariant = Color(0xFF171B45);
    const Color outline = Color(0xFF353B6D);
    const Color tertiary = Color(0xFF5BE6C4);
    const Color error = Color(0xFFFF6B8A);

    final ColorScheme colorScheme = ColorScheme(
      brightness: Brightness.dark,
      primary: primary,
      onPrimary: Colors.white,
      secondary: secondary,
      onSecondary: Colors.white,
      tertiary: tertiary,
      onTertiary: const Color(0xFF021B16),
      error: error,
      onError: Colors.white,
      background: background,
      onBackground: Colors.white,
      surface: surface,
      onSurface: Colors.white,
      surfaceVariant: surfaceVariant,
      onSurfaceVariant: Colors.white70,
      outline: outline,
      outlineVariant: outline.withOpacity(0.6),
      shadow: Colors.black.withOpacity(0.75),
      scrim: Colors.black.withOpacity(0.8),
      inverseSurface: const Color(0xFFECEAFF),
      onInverseSurface: const Color(0xFF1B1F3E),
      inversePrimary: const Color(0xFFA8A3FF),
    );

    final TextTheme baseTextTheme = ThemeData(brightness: Brightness.dark).textTheme;
    final TextTheme textTheme = baseTextTheme.copyWith(
      displayLarge: const TextStyle(
        fontSize: 54,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.5,
      ),
      displayMedium: const TextStyle(
        fontSize: 44,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.4,
      ),
      displaySmall: const TextStyle(
        fontSize: 32,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.3,
      ),
      headlineLarge: const TextStyle(
        fontSize: 30,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.2,
      ),
      headlineMedium: const TextStyle(
        fontSize: 26,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.2,
      ),
      headlineSmall: const TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.w600,
      ),
      titleLarge: const TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w600,
      ),
      titleMedium: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w600,
      ),
      titleSmall: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
      ),
      bodyLarge: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        height: 1.5,
      ),
      bodyMedium: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        height: 1.5,
      ),
      bodySmall: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.2,
      ),
      labelLarge: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.3,
      ),
      labelMedium: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.3,
      ),
      labelSmall: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.4,
      ),
    ).apply(
      bodyColor: Colors.white,
      displayColor: Colors.white,
    );

    const DreamGradients gradients = DreamGradients.fallback;
    const DreamCardTheme cardTheme = DreamCardTheme.fallback;
    const DreamButtonTheme buttonTheme = DreamButtonTheme.fallback;

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      fontFamily: 'DreamFont',
      scaffoldBackgroundColor: Colors.transparent,
      colorScheme: colorScheme,
      textTheme: textTheme,
      snackBarTheme: SnackBarThemeData(
        backgroundColor: colorScheme.surfaceVariant.withOpacity(0.85),
        contentTextStyle: textTheme.bodyMedium?.copyWith(
          color: colorScheme.onSurface,
          fontWeight: FontWeight.w600,
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      dialogBackgroundColor: colorScheme.surface.withOpacity(0.95),
      cardColor: colorScheme.surfaceVariant,
      dividerColor: outline.withOpacity(0.5),
      extensions: const <ThemeExtension<dynamic>>[
        gradients,
        cardTheme,
        buttonTheme,
      ],
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          textStyle: textTheme.labelLarge,
          padding: buttonTheme.padding,
          shape: RoundedRectangleBorder(borderRadius: buttonTheme.borderRadius),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          textStyle: textTheme.labelLarge,
          foregroundColor: colorScheme.onPrimary,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colorScheme.surfaceVariant.withOpacity(0.6),
        border: OutlineInputBorder(
          borderRadius: cardTheme.borderRadius,
          borderSide: BorderSide(color: outline.withOpacity(0.4)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: cardTheme.borderRadius,
          borderSide: BorderSide(color: colorScheme.primary.withOpacity(0.8)),
        ),
        labelStyle: textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant),
      ),
      iconTheme: IconThemeData(color: colorScheme.onBackground),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        titleTextStyle: textTheme.titleLarge,
        foregroundColor: colorScheme.onBackground,
        centerTitle: false,
      ),
    );
  }
}
