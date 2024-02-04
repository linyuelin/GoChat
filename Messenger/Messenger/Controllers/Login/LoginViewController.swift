//
//  LoginViewController.swift
//  Messenger
//
//  Created by dreaMTank on 2024/01/31.
//

import UIKit
import Firebase
import FBSDKLoginKit
import JGProgressHUD

class LoginViewController: UIViewController {
    private let spinner = JGProgressHUD(style: .dark)

    
    
    private let imageView: UIImageView = {
        let image =  UIImageView()
        image.image = UIImage(named: "logo")
        image.contentMode  = .scaleAspectFit
        return image
    }()
    
    //スクロールビュー
    private let scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.clipsToBounds = true   //内部のビューが境界を超えたら、切り取られる
        return scrollView
    }()
    
    private let emailField: UITextField = {
        let field = UITextField()
        //入力時の自動大文字化を無効にする
        field.autocapitalizationType = .none
        //自動修正を無効にする
        field.autocorrectionType = .no
        //リターンキーを「続行」にする
        field.returnKeyType = .continue
        //角を丸くする
        field.layer.cornerRadius = 12
        field.layer.borderWidth = 1
        field.layer.borderColor = UIColor.lightGray.cgColor
        //プレースホルダーテキストを設定する
        field.placeholder = "メールアドレス"
        //テキスト内で固定された幅五ポイントの余白を追加する
        field.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 5, height: 0))
        field.leftViewMode = .always
        field.backgroundColor = .white
        return field
    }()
    
    
    private let passwordField: UITextField = {
        let field = UITextField()
        //入力時の自動大文字化を無効にする
        field.autocapitalizationType = .none
        //自動修正を無効にする
        field.autocorrectionType = .no
        //リターンキーを「続行」にする
        field.returnKeyType = .done
        //角を丸くする
        field.layer.cornerRadius = 12
        field.layer.borderWidth = 1
        field.layer.borderColor = UIColor.lightGray.cgColor
        //プレースホルダーテキストを設定する
        field.placeholder = "パスワード"
        //テキスト内で固定された幅五ポイントの余白を追加する
        field.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 5, height: 0))
        field.leftViewMode = .always
        field.backgroundColor = .white
        field.isSecureTextEntry = true
        return field
    }()
    
    private let loginButton: UIButton = {
       let button = UIButton()
        button.setTitle("ログイン", for: .normal)
        button.backgroundColor = .link
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 12
        button.layer.masksToBounds = true
        button.titleLabel?.font = .systemFont(ofSize: 20 , weight: .bold)
        return button
    }()
    
    
    private let facebookLoginButton: FBLoginButton = {
        let button = FBLoginButton()
        button.permissions = ["email" , "public_profile"]
        return button
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.addSubview(scrollView)
        scrollView.addSubview(imageView)
        scrollView.addSubview(emailField)
        scrollView.addSubview(passwordField)
        scrollView.addSubview(loginButton)
        scrollView.addSubview(facebookLoginButton)
        
        title = "ログイン"
        view.backgroundColor = .white
   
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "登録", style: .done, target: self, action: #selector(didTapRegister))
        
        //ボタンとファンクションのバインディング
        loginButton.addTarget(self, action: #selector(loginButtonTapped), for: .touchUpInside)
        
        emailField.delegate = self
        passwordField.delegate = self
        facebookLoginButton.delegate = self
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        scrollView.frame = view.bounds
        
        let size = scrollView.width/3
        imageView.frame = CGRect(x:(scrollView.width - size)/2 , y: 20, width: size, height: size)
        
        emailField.frame = CGRect(x:30 , y: imageView.bottom + 10, width: scrollView.width - 60, height: 52)
        
        passwordField.frame = CGRect(x:30 , y: emailField.bottom + 10, width: scrollView.width - 60, height: 52)
        
        loginButton.frame = CGRect(x:30 , y: passwordField.bottom + 10, width: scrollView.width - 60, height: 52)
        
        facebookLoginButton.frame = CGRect(x:30 , y: loginButton.bottom + 10, width: scrollView.width - 60, height: 52)
        
//        facebookLoginButton.frame.origin.y = loginButton.bottom + 20
    }
    
    @objc private func  loginButtonTapped() {
        
        //キーボードが閉じられ、その後ログイン処理が続きます
        emailField.resignFirstResponder()
        passwordField.resignFirstResponder()
        
        guard let email = emailField.text , let password = passwordField.text ,
              !email.isEmpty , !password.isEmpty ,password.count >= 6 else {
            alertUserLoginError()
            return
        }
        
        //　スピナーを表示する
        spinner.show(in: view)
        //Firebaseを介してサインインする
        FirebaseAuth.Auth.auth().signIn(withEmail: email , password: password , completion: { [weak self]
            authResult , error in
            
            guard let strongSelf = self else {
                return
            }
            
            // ビューはメインメソッドにアサイン
            DispatchQueue.main.async{
                strongSelf.spinner.dismiss()
            }
            
            
            guard let result = authResult , error == nil else {
                print("\(email)ログイン失敗")
                      return
            }
              
            strongSelf.navigationController?.dismiss(animated: true, completion: nil)
            
        })
    }
    
    func  alertUserLoginError() {
        let alert = UIAlertController(title: "エラー", message: "もう一度お試しください", preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "閉じる", style: .cancel, handler: nil))
        
        present(alert, animated: true)
    }
    
    @objc private func didTapRegister(){
        let vc = RegisterViewController()
        vc.title = "アカウントを作成"
        navigationController?.pushViewController(vc, animated: true)
    }

   
}


extension  LoginViewController: UITextFieldDelegate {
    
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        
        //メールアドレスのテキストフィールドでリターンキーが押された場合、パスワードにフォーカスを移す
        if textField == emailField {
            passwordField.becomeFirstResponder()
        }
        //押された場合、ログインボタンの処理を実行する
        else if textField == passwordField {
            
            loginButtonTapped()
        }
        return true
    }
}


//facebookによってログインする
extension LoginViewController: LoginButtonDelegate {
    
    // ログアウトする際
    func loginButtonDidLogOut(_ loginButton: FBLoginButton) {
        
    }
    
    //ログイン
    func loginButton(_ loginButton: FBSDKLoginKit.FBLoginButton, didCompleteWith result: FBSDKLoginKit.LoginManagerLoginResult?, error: (Error)?) {
        
        //トークンが取得できなかった場合の処理
        guard let token = result?.token?.tokenString else {
            print("facebookでログインに失敗しました")
            return
        }
        
        let facebookRequest = FBSDKLoginKit.GraphRequest(graphPath: "me", parameters: ["fields" : "email , name" ], tokenString: token, version: nil, httpMethod: .get)
        
        facebookRequest.start(completion: {_, result , error in
            
            
            print(result)
            
            guard let result = result as? [String: Any], error == nil else {
                print("グラフリクエストの生成に失敗")
                return
            }
            guard let userName = result["name"] as? String, let email = result["email"] as? String else{
                print("イーメールとネームのゲットに失敗")
                return
            }
            //　空白で分割して、二つの要素に分ける
            let nameComponents = userName.components(separatedBy: " ")
            
            guard nameComponents.count == 2 else {
                return
            }
            
            let firstName = nameComponents[0]
            let lastName = nameComponents[1]
            
            DatabaseManager.shared.userExists(with: email, completion: { exists in
                if !exists {
                    DatabaseManager.shared.insertUser(with: ChatAppUser(firstName: firstName, lastName: lastName, emailAddress: email))
                }
            })
            // Facebookのアクセストークンを使用してFirebaseの認証トークンを作成
            let credential = FacebookAuthProvider.credential(withAccessToken: token)
            
            // Firebaseでユーザーをログインさせる
            FirebaseAuth.Auth.auth().signIn(with: credential, completion: { [weak self] authResult ,error in
                
                guard  let strongSelf = self else {
                    return
                }
                // ログイン結果とエラーを確認
                guard authResult != nil , error == nil else {
                    if let error = error{
                        // ログインに失敗した場合のエラー処理
                        print("Facebookの資格情報によるログインに失敗しました\(error)")
                    }
                    return
                }
                // ログイン成功時の処理
                print("ユーザーが正常にログインしました")
                strongSelf.navigationController?.dismiss(animated: true, completion: nil)
            })
        })
        
    }
    
}
    
   

