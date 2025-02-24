import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

class MeScreen extends StatefulWidget {
  const MeScreen({super.key});

  @override
  State<MeScreen> createState() => _MeScreenState();
}

class _MeScreenState extends State<MeScreen> with TickerProviderStateMixin {
  // ========== 1. 惯性漂浮用到的位移 & 速度 ==========
  double _posX = 0; // 当前卡片相对于“初始中心”的 X 偏移
  double _posY = 0; // 当前卡片相对于“初始中心”的 Y 偏移
  double _velX = 0; // X 平移速度 (像素/帧)
  double _velY = 0; // Y 平移速度 (像素/帧)

  // 你可以调大/调小下面这两个系数来控制“拖拽 -> 速度” 和 “速度衰减”
  final double _dragToVelocityFactor = 0.3; // 拖拽距离 -> 惯性速度的映射
  final double _friction = 0.98; // 摩擦系数(越接近1衰减越慢)

  // ========== 2. 轻微倾斜动画相关 ==========
  late AnimationController _tiltController;
  late Animation<double> _tiltAnimation;
  // 倾斜到多少度（弧度），此处 10° = π/18
  final double _maxTiltRadians = math.pi / 18;

  // ========== 3. 双击翻转动画相关 ==========
  late AnimationController _flipController;
  late Animation<double> _flipAnimation;
  bool _isFlipped = false; // 记录当前是否已翻面

  // ========== 卡片基本信息 ==========
  final double cardWidth = 200;
  final double cardHeight = 120;

  // ========== 动画驱动 (Ticker) - 处理惯性漂移 ==========
  late final Ticker _ticker;

  // ========== 父容器大小，用于边界检测 ==========
  double? _screenWidth;
  double? _screenHeight;

  // 手势按下时计算卡片中心，辅助拖拽
  Offset _cardCenter = Offset.zero;

  @override
  void initState() {
    super.initState();

    // ========== A) 创建 Ticker 用于惯性漂浮 ==========
    _ticker = createTicker(_onTick);
    _ticker.start();

    // ========== B) 轻微倾斜动画 ==========
    _tiltController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    // 从 0 到 _maxTiltRadians
    _tiltAnimation = Tween<double>(begin: 0, end: _maxTiltRadians).animate(
      CurvedAnimation(parent: _tiltController, curve: Curves.easeOut),
    );

    // ========== C) 双击翻转动画 ==========
    _flipController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    // 从 0 到 π（180°）
    _flipAnimation = Tween<double>(begin: 0, end: math.pi).animate(
      CurvedAnimation(parent: _flipController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ticker.dispose();
    _tiltController.dispose();
    _flipController.dispose();
    super.dispose();
  }

  // 每帧都执行 - 让卡片带着速度漂浮，并进行边界检测
  void _onTick(Duration elapsed) {
    if (!mounted) return;

    setState(() {
      // 1) 累加平移
      _posX += _velX;
      _posY += _velY;

      // 2) 速度衰减
      _velX *= _friction;
      _velY *= _friction;

      // 3) 边界检测
      _clampPosition();
    });
  }

  // 确保卡片不会跑到屏幕外
  void _clampPosition() {
    if (_screenWidth == null || _screenHeight == null) return;

    final centerX = (_screenWidth! - cardWidth) / 2;
    final centerY = (_screenHeight! - cardHeight) / 2;

    final minX = -centerX;
    final maxX = (_screenWidth! - cardWidth) - centerX;

    final minY = -centerY;
    final maxY = (_screenHeight! - cardHeight) - centerY;

    if (_posX < minX) {
      _posX = minX;
      _velX = 0;
    } else if (_posX > maxX) {
      _posX = maxX;
      _velX = 0;
    }

    if (_posY < minY) {
      _posY = minY;
      _velY = 0;
    } else if (_posY > maxY) {
      _posY = maxY;
      _velY = 0;
    }
  }

  // ========== 手势事件：拖拽 ==========
  void _onPanStart(DragStartDetails details) {
    // 计算卡片在屏幕中的绝对坐标(左上角)，转成中心
    final box = context.findRenderObject() as RenderBox?;
    if (box != null) {
      final offset = box.localToGlobal(Offset.zero);
      _cardCenter = Offset(
        offset.dx + cardWidth / 2,
        offset.dy + cardHeight / 2,
      );
    }
  }

  void _onPanUpdate(DragUpdateDetails details) {
    setState(() {
      // 拖拽增量
      final delta = details.delta;

      // 将拖拽距离映射到速度
      _velX = delta.dx * _dragToVelocityFactor;
      _velY = delta.dy * _dragToVelocityFactor;

      // 为了让卡片与手指更贴合，也可以立即更新位置
      _posX += delta.dx * 0.2;
      _posY += delta.dy * 0.2;
    });
  }

  void _onPanEnd(DragEndDetails details) {
    // 不清零速度，卡片继续惯性飘
  }

  // ========== 手势事件：轻微倾斜与翻转 ==========
  // 按下时倾斜
  void _onTapDown(TapDownDetails details) {
    _tiltController.forward();
  }

  // 松开时回正
  void _onTapUp(TapUpDetails details) {
    _tiltController.reverse();
  }

  void _onTapCancel() {
    _tiltController.reverse();
  }

  // 双击翻转
  void _onDoubleTap() {
    if (_isFlipped) {
      _flipController.reverse();
    } else {
      _flipController.forward();
    }
    _isFlipped = !_isFlipped;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Inertia + Slight Tilt + DoubleTap Flip'),
      ),
      body: LayoutBuilder(
        builder: (ctx, constraints) {
          _screenWidth = constraints.maxWidth;
          _screenHeight = constraints.maxHeight;

          return Stack(
            children: [
              // 使用 Positioned 将卡片定位到 “初始中心 + 偏移”
              Positioned(
                left: (constraints.maxWidth - cardWidth) / 2 + _posX,
                top: (constraints.maxHeight - cardHeight) / 2 + _posY,
                child: GestureDetector(
                  // 拖拽相关
                  onPanStart: _onPanStart,
                  onPanUpdate: _onPanUpdate,
                  onPanEnd: _onPanEnd,

                  // 轻微倾斜相关
                  onTapDown: _onTapDown,
                  onTapUp: _onTapUp,
                  onTapCancel: _onTapCancel,

                  // 翻转相关
                  onDoubleTap: _onDoubleTap,

                  child: AnimatedBuilder(
                    // 同时监听倾斜动画 & 翻转动画
                    animation:
                        Listenable.merge([_tiltController, _flipController]),
                    builder: (context, child) {
                      final tilt = _tiltAnimation.value; // 0 ~ _maxTiltRadians
                      final flip = _flipAnimation.value; // 0 ~ π

                      // 先做轻微倾斜(绕X轴)，再做翻转(绕Y轴)
                      final transform = Matrix4.identity()
                        ..setEntry(3, 2, 0.001)
                        ..rotateX(tilt)
                        ..rotateY(flip);

                      return Transform(
                        alignment: Alignment.center,
                        transform: transform,
                        child: Container(
                          width: cardWidth,
                          height: cardHeight,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: Colors.blueAccent,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: const [
                              BoxShadow(
                                color: Colors.black26,
                                blurRadius: 8,
                                offset: Offset(0, 4),
                              ),
                            ],
                          ),
                          child: _buildCardContent(),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // 根据翻转动画的数值决定显示正面 / 背面
  Widget _buildCardContent() {
    final flipAngle = _flipAnimation.value;
    final isBack = flipAngle > math.pi / 2;

    // 背面
    if (isBack) {
      return Transform(
        transform: Matrix4.rotationY(math.pi),
        alignment: Alignment.center,
        child: const Text(
          'Back Side',
          style: TextStyle(color: Colors.white, fontSize: 18),
        ),
      );
    } else {
      // 正面
      return const Text(
        'Front Side',
        style: TextStyle(color: Colors.white, fontSize: 18),
      );
    }
  }
}
