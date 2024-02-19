//
//  RegisterViewController.swift
//  Messenger
//
//  Created by dreaMTank on 2024/01/31.
//

import UIKit
import FirebaseAuth
import JGProgressHUD

class RegisterViewController: UIViewController {
    
    private let spinner = JGProgressHUD(style: .dark)
    
    
    private let imageView: UIImageView = {
        let image =  UIImageView()
        image.image = UIImage(systemName:  "person.circle")
        image.tintColor = .gray  //画像の色をグレーに設定する
        image.contentMode  = .scaleAspectFit
        image.layer.masksToBounds = true
        image.layer.borderWidth = 2
        image.layer.borderColor = UIColor.lightGray.cgColor
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
        field.backgroundColor = .secondarySystemBackground
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
        field.backgroundColor = .secondarySystemBackground
        field.isSecureTextEntry = false
        return field
    }()
    
    private let firstNameField: UITextField = {
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
        field.placeholder = "姓"
        //テキスト内で固定された幅五ポイントの余白を追加する
        field.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 5, height: 0))
        field.leftViewMode = .always
        field.backgroundColor = .secondarySystemBackground
        return field
    }()
    
    private let lastNameField: UITextField = {
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
        field.placeholder = "名"
        //テキスト内で固定された幅五ポイントの余白を追加する
        field.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 5, height: 0))
        field.leftViewMode = .always
        field.backgroundColor = .secondarySystemBackground
        return field
    }()
    
    private let registerButton: UIButton = {
       let button = UIButton()
        button.setTitle("登録", for: .normal)
        button.backgroundColor = .systemGreen
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
        scrollView.addSubview(firstNameField)
        scrollView.addSubview(lastNameField)
        scrollView.addSubview(emailField)
        scrollView.addSubview(passwordField)
        scrollView.addSubview(registerButton)
        
        title = "ログイン"
        view.backgroundColor = .secondarySystemBackground
   
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "登録", style: .done, target: self, action: #selector(didTapRegister))
        
        //ボタンとファンクションのバインディング
        registerButton.addTarget(self, action: #selector(registerButtonTapped), for: .touchUpInside)
        
        emailField.delegate = self
        passwordField.delegate = self
        lastNameField.delegate = self
        firstNameField.delegate = self
        
        // イメージのユーザーインタラクションを有効にする
        imageView.isUserInteractionEnabled = true
        //スクロールの
        scrollView.isUserInteractionEnabled = true
        
        //gesture の生成と設定
        let gesture = UITapGestureRecognizer(target: self, action: #selector(didTapChangeProfilePic))
        
        // imageView にジェスチャーを追加
        imageView.addGestureRecognizer(gesture)
    }
    
    @objc private func didTapChangeProfilePic() {
        presentPhotoActionSheet()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        scrollView.frame = view.bounds
        
        let size = scrollView.width/3
        imageView.frame = CGRect(x:(scrollView.width - size)/2 , y: 20, width: size, height: size)
        imageView.layer.cornerRadius = imageView.width/2.0
        
        firstNameField.frame = CGRect(x:30 , y: imageView.bottom + 10, width: scrollView.width - 60, height: 52)
        
        lastNameField.frame = CGRect(x:30 , y: firstNameField.bottom + 10, width: scrollView.width - 60, height: 52)
        
        emailField.frame = CGRect(x:30 , y: lastNameField.bottom + 10, width: scrollView.width - 60, height: 52)
        
        passwordField.frame = CGRect(x:30 , y: emailField.bottom + 10, width: scrollView.width - 60, height: 52)
        
        registerButton.frame = CGRect(x:30 , y: passwordField.bottom + 10, width: scrollView.width - 60, height: 52)
    }
    
    @objc private func  registerButtonTapped() {
        
        //キーボードが閉じられ、その後ログイン処理が続きます
        emailField.resignFirstResponder()
        passwordField.resignFirstResponder()
        firstNameField.resignFirstResponder()
        lastNameField.resignFirstResponder()
        
        guard let firstName = firstNameField.text ,let lastName = lastNameField.text ,let email = emailField.text , let password = passwordField.text ,
              
                !email.isEmpty , !firstName.isEmpty ,!lastName.isEmpty , !password.isEmpty ,password.count >= 6 else {
            alertUserLoginError()
            return
        }
        
        spinner.show(in: view)
        
        DatabaseManager.shared.userExists(with: email, completion: { [weak self] exists in
            
            guard let strongSelf = self else{
                return
            }
            
            DispatchQueue.main.async {
                strongSelf.spinner.dismiss()
            }
            
            guard !exists else {
                //存在してるユーザー
                strongSelf.alertUserLoginError(message: "このメールアドレスは既に使用されています。別のメールアドレスを試してください。")
                return
            }
            
            FirebaseAuth.Auth.auth().createUser(withEmail: email, password: password,completion: { authResult , error in
                
               
                
                guard  authResult != nil  , error == nil else {
                    print("アカンウト作成に失敗")
                    return
                }
               
                //成功した場合
                let chatUser = ChatAppUser(firstName: firstName, lastName: lastName, emailAddress: email)
                DatabaseManager.shared.insertUser(with: chatUser , completion: { success in
                    if success {
                        //画像をアップロード
                        guard let image = strongSelf.imageView.image,
                              // imageをPNG形式のバイナリデータに変換する
                              let data = image.pngData() else {
                            return
                        }
                        
                        let filename = chatUser.profilePictureFileName
                        StorageManager.shared.uploadProfilePicture(with: data, fileName: filename, completion: { result in
                            switch result {
                            case .success(let dowmloadUrl):
                                //ユーザーのデフォルト設定に保存する 
                                UserDefaults.standard.set( dowmloadUrl, forKey: "profile_picture_url")
                               
                            case .failure(let error):
                                print("Storage に画像をアップロードすることに失敗した \(error)")
                            }
                        })
                    }
                })
                
                strongSelf.navigationController?.dismiss(animated: true, completion: nil)
            })
            
        })
    }
        
    
    func  alertUserLoginError(message: String = "すべての情報を入力してください") {
        let alert = UIAlertController(title: "エラー", message:message , preferredStyle: .alert
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


extension RegisterViewController: UITextFieldDelegate {
    
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        
        if textField == firstNameField {
            lastNameField.becomeFirstResponder()
        }
        else if textField == lastNameField {
            emailField.becomeFirstResponder()
        }
        //メールアドレスのテキストフィールドでリターンキーが押された場合、パスワードにフォーカスを移す
        else if textField == emailField {
            passwordField.becomeFirstResponder()
        }
        //押された場合、ログインボタンの処理を実行する
        else if  textField == passwordField {
            
            textField.resignFirstResponder()
        }
        return true
    }
}

extension RegisterViewController: UIImagePickerControllerDelegate , UINavigationControllerDelegate{
   
    //　アクションシート各オプションを追加
    func presentPhotoActionSheet() {
        
        let actionSheet = UIAlertController(title: "プロフィール画像編集", message: "以下のを選択してください", preferredStyle: .actionSheet)
        
        actionSheet.addAction(UIAlertAction(title: "キャンセル", style: .cancel, handler: nil))
        
        actionSheet.addAction(UIAlertAction(title: "カメラで撮影", style: .default, handler: { [weak self]_ in   self?.presentCamera()
            
        }))
        
        actionSheet.addAction(UIAlertAction(title: "写真を選択", style: .default, handler:  {[weak self]_ in
            self?.presentPhotoPicker()
        }))
        
        // アクションシートを表示
        present(actionSheet, animated: true)
        
    }
    
    //カメラを表示し
    func presentCamera() {
        let vc = UIImagePickerController()
        vc.sourceType = .camera
        vc.delegate = self
        vc.allowsEditing = true
        present(vc, animated: true)
    }
    
    
     //写真ライブラリを表示する
    func presentPhotoPicker(){
        let vc = UIImagePickerController()
        vc.sourceType = .photoLibrary
        vc.delegate = self
        vc.allowsEditing = true
        present(vc, animated: true)
    }
    
    //UIImagePickerControllerから写真の選択または撮影後のコールバックメソッド
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        
        //UIImagePickerControllerを閉じる
        picker.dismiss(animated: true , completion: nil)
        
        //　コールバックから編集後の画像を取得
        guard  let selectedImage  = info[UIImagePickerController.InfoKey.editedImage] as? UIImage else {
            return
        }
        
        //選択された画像をimageViewの画像として設定
        self.imageView.image = selectedImage
    }
    
    
     //ユーザーが画像の選択をキャンセルした際のコールバックメソッド
    func  imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
    }
    
    
}
