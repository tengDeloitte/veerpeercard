import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:veerpeercard/config/clientId.dart';
import 'package:veerpeercard/utils/logger.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _resetEmailController = TextEditingController();
  bool _isLoading = false;
  bool _isLoginMode = true;

  // 添加: 密码可见性状态变量
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  // 密码重置
  Future<void> _handlePasswordReset() async {
    // 创建一个dialog来获取用户的邮箱
    return showDialog(
      context: context,
      builder: (dialogContext) { // 修改: 使用明确的dialogContext变量名，避免混淆
        return AlertDialog(
          title: const Text('Reset Password'),
          content: TextField(
            controller: _resetEmailController,
            decoration: const InputDecoration(
              labelText: 'Email',
              hintText: 'Enter your email',
            ),
            keyboardType: TextInputType.emailAddress,
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                if (_resetEmailController.text.isEmpty) {
                  // 修改: 这里不需要async检查，因为还没有async操作
                  ScaffoldMessenger.of(dialogContext).showSnackBar(
                    const SnackBar(content: Text('Please enter your email')),
                  );
                  return;
                }

                // 修改: 保存邮箱，并在async操作前关闭对话框
                final email = _resetEmailController.text.trim();
                _resetEmailController.clear();
                Navigator.of(dialogContext).pop();

                try {
                  // 修改: 使用保存的email变量
                  await FirebaseAuth.instance.sendPasswordResetEmail(
                    email: email,
                  );

                  // 修改: 添加mounted检查，防止在异步操作后使用context
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Password reset email sent. Please check your inbox.'),
                      ),
                    );
                  }
                } catch (e) {
                  // 修改: 移除Navigator.pop，因为对话框已经在异步操作前关闭

                  String errorMessage = 'Failed to send password reset email';
                  if (e.toString().contains('user-not-found')) {
                    errorMessage = 'No user found with this email';
                  } else if (e.toString().contains('invalid-email')) {
                    errorMessage = 'The email address is badly formatted';
                  } else {
                    errorMessage = e.toString().split(']').length > 1 ?
                    e.toString().split(']')[1].trim() : e.toString();
                  }

                  // 修改: 添加mounted检查
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(errorMessage)),
                    );
                  }
                }
              },
              child: const Text('Send Reset Link'),
            ),
          ],
        );
      },
    );
  }

  // google sign-in
  Future<void> _handleGoogleSignIn() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // 初始化Google登录时添加配置参数
      final GoogleSignIn googleSignIn = GoogleSignIn(
        scopes: ['email'],
        signInOption: SignInOption.standard, // 使用标准登录流程
        hostedDomain: '', // 空字符串允许任何域
        clientId: AppConfig.googleClientId, // 可选，通常不需要手动设置
      );

      // 强制显示账户选择器
      await googleSignIn.signOut(); // 先登出当前账户
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();

      if (googleUser == null) {
        if (mounted) setState(() { _isLoading = false; });
        return; // 用户取消登录
      }

      // 获取Google授权凭证
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      // 创建Firebase凭证
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // 使用Firebase凭证登录
      await FirebaseAuth.instance.signInWithCredential(credential);
    } catch (e) {
      if (mounted) {
        logger.e('Google Sign In Error', e, StackTrace.current);

        String errorMessage = 'Google sign in failed';
        if (e.toString().contains('network')) {
          errorMessage = 'Network error occurred';
        } else if (e.toString().contains('canceled')) {
          errorMessage = 'Sign in was canceled';
        } else if (e.toString().contains('credential')) {
          errorMessage = 'Invalid credentials';
        } else if (e.toString().contains('account-exists-with-different-credential')) {
          errorMessage = 'An account already exists with the same email address';
        } else {
          errorMessage = e.toString().split(']').length > 1 ?
          e.toString().split(']')[1].trim() : e.toString();
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage)),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // 邮箱注册
  Future<void> _handleEmailPasswordAuth() async {
    if (_emailController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your email')),
      );
      return;
    }

    if (_passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your password')),
      );
      return;
    }

    if (!_isLoginMode && _passwordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Passwords do not match')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      if (_isLoginMode) {
        await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );
      } else {
        await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );
      }
    } catch (e) {
      if (mounted) {
        String errorMessage = 'An error occurred';
        if (e.toString().contains('invalid-email')) {
          errorMessage = 'The email address is badly formatted';
        } else if (e.toString().contains('user-not-found')) {
          errorMessage = 'No user found with this email';
        } else if (e.toString().contains('wrong-password')) {
          errorMessage = 'Wrong password provided';
        } else if (e.toString().contains('email-already-in-use')) {
          errorMessage = 'This email is already registered';
        } else if (e.toString().contains('weak-password')) {
          errorMessage = 'The password is too weak';
        } else {
          // 如果是其他错误，可以选择显示原始信息或自定义信息
          errorMessage = e.toString().split(']').length > 1 ?
          e.toString().split(']')[1].trim() : e.toString();
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage)),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isLoginMode ? 'Login' : 'Sign up'),
        // 在注册模式下显示返回按钮
        leading: !_isLoginMode ? IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            setState(() {
              _isLoginMode = true;
              _passwordController.clear();
              _confirmPasswordController.clear();
            });
          },
        ) : null,
      ),
      // 设置为false，我们将手动处理键盘弹出的情况
      resizeToAvoidBottomInset: false,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: ListView(
            children: [
              const SizedBox(height: 20),
              // 电子邮件字段
              TextField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),

              // 修改: 密码字段添加显示/隐藏按钮
              TextField(
                controller: _passwordController,
                decoration: InputDecoration(
                  labelText: 'Password',
                  border: const OutlineInputBorder(),
                  // 添加: 密码可见性切换按钮
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword ? Icons.visibility_off : Icons.visibility,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                  ),
                ),
                obscureText: _obscurePassword, // 修改: 使用状态变量控制密码可见性
              ),
              const SizedBox(height: 8),

              // "Trouble logging in?"链接（仅在登录模式下显示）
              if (_isLoginMode)
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: _handlePasswordReset,
                    child: const Text(
                      'Trouble logging in?',
                      style: TextStyle(
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),

              const SizedBox(height: 8),

              // 确认密码字段（仅在注册模式下显示）
              if (!_isLoginMode) ...[
                // 修改: 确认密码字段添加显示/隐藏按钮
                TextField(
                  controller: _confirmPasswordController,
                  decoration: InputDecoration(
                    labelText: 'Confirm Password',
                    border: const OutlineInputBorder(),
                    // 添加: 确认密码可见性切换按钮
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureConfirmPassword ? Icons.visibility_off : Icons.visibility,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscureConfirmPassword = !_obscureConfirmPassword;
                        });
                      },
                    ),
                  ),
                  obscureText: _obscureConfirmPassword, // 修改: 使用状态变量控制密码可见性
                ),
                const SizedBox(height: 16),
              ],

              // 登录/注册按钮或加载指示器
              if (_isLoading)
                const Center(child: CircularProgressIndicator())
              else
                Column(
                  children: [
                    // Email/Password 登录按钮
                    ElevatedButton(
                      onPressed: _handleEmailPasswordAuth,
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 50),
                      ),
                      child: Text(_isLoginMode ? 'Login' : 'Sign up'),
                    ),
                    const SizedBox(height: 24),
                    // 或者使用分隔线
                    Row(
                      children: const [
                        Expanded(child: Divider()),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16),
                          child: Text('OR', style: TextStyle(color: Colors.grey)),
                        ),
                        Expanded(child: Divider()),
                      ],
                    ),
                    const SizedBox(height: 24),
                    // Google登录按钮
                    Center(
                      child: Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                          border: Border.all(
                            color: Colors.grey.shade300,
                            width: 1,
                          ),
                        ),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(25),
                          onTap: _handleGoogleSignIn,
                          child: Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Image.network(
                              'https://cdn1.iconfinder.com/data/icons/google-s-logo/150/Google_Icons-09-512.png',
                              width: 24,
                              height: 24,
                              errorBuilder: (context, error, stackTrace) =>
                              const Icon(Icons.g_mobiledata, size: 24),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    // 切换登录/注册模式按钮
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _isLoginMode = !_isLoginMode;
                          _passwordController.clear();
                          _confirmPasswordController.clear();
                        });
                      },
                      child: Text(
                        _isLoginMode
                            ? 'New to Veerpeer card? Sign up'
                            : 'Already have an account? Login',
                      ),
                    ),
                  ],
                ),

              // 底部添加额外空间，确保最后的元素在键盘弹出时可见
              SizedBox(height: MediaQuery.of(context).viewInsets.bottom > 0
                  ? MediaQuery.of(context).viewInsets.bottom
                  : 20),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }
}