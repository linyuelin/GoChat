//
//  LoginViewController.swift
//  Messenger
//
//  Created by dreaMTank on 2024/01/31.
//

import UIKit

class LoginViewController: UIViewController {

    
    
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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.addSubview(scrollView)
        scrollView.addSubview(imageView)
        scrollView.addSubview(emailField)
        scrollView.addSubview(passwordField)
        scrollView.addSubview(loginButton)
        title = "ログイン"
        view.backgroundColor = .white
   
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "登録", style: .done, target: self, action: #selector(didTapRegister))
        
        //ボタンとファンクションのバインディング
        loginButton.addTarget(self, action: #selector(loginButtonTapped), for: .touchUpInside)
        
        emailField.delegate = self
        passwordField.delegate = self
        
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        scrollView.frame = view.bounds
        
        let size = scrollView.width/3
        imageView.frame = CGRect(x:(scrollView.width - size)/2 , y: 20, width: size, height: size)
        
        emailField.frame = CGRect(x:30 , y: imageView.bottom + 10, width: scrollView.width - 60, height: 52)
        
        passwordField.frame = CGRect(x:30 , y: emailField.bottom + 10, width: scrollView.width - 60, height: 52)
        
        loginButton.frame = CGRect(x:30 , y: passwordField.bottom + 10, width: scrollView.width - 60, height: 52)
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
        //Firebaseを介してサインインする
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