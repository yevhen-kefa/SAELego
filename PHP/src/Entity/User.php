<?php
class User {

    private $user_id;
    private $nickname;
    private $email;
    private $password;
    private $verified;
    private $created_at;
    private $firstname;
    private $lastname;
    private $phone_number;
    private $birth_year;
    private $address;
    private $role;
    private $two_factor_code;
    private $two_factor_expires_at;
    private $reset_token;
    private $reset_expires_at;

    public function __construct(array $data = []) {
        if (!empty($data)) $this->hydrate($data);
    }

    private function hydrate(array $data) {
        foreach ($data as $key => $value) {
            $method = 'set' . str_replace('_', '', ucwords($key, '_'));
            if (method_exists($this, $method)) {
                $this->$method($value);
            }
        }
    }

    public function getIdUser() { return $this->user_id; }
    public function getUsername() { return $this->nickname; } 
    public function getEmail() { return $this->email; }
    public function getPassword() { return $this->password; }
    public function getRole() { return $this->role ?? 'user'; }
    public function getFirstname() { return $this->firstname; }
    public function getLastname() { return $this->lastname; }
    public function getPhoneNumber() { return $this->phone_number; }
    public function getAddress() { return $this->address; }
    public function getBirthYear() { return $this->birth_year; }
    public function getTwoFactorCode() { return $this->two_factor_code; }
    public function getTwoFactorExpiresAt() { return $this->two_factor_expires_at; }
    public function isVerified() { return $this->verified; }

    public function setUserId($id) { $this->user_id = $id; }
    public function setNickname($n) { $this->nickname = $n; }
    public function setUsername($n) { $this->nickname = $n; }
    public function setEmail($e) { $this->email = $e; }
    public function setPassword($p) { $this->password = $p; }
    public function setFirstname($f) { $this->firstname = $f; }
    public function setLastname($l) { $this->lastname = $l; }
    public function setPhoneNumber($p) { $this->phone_number = $p; }
    public function setAddress($a) { $this->address = $a; }
    public function setBirthYear($b) { $this->birth_year = $b; }
    public function setRole($r) { $this->role = $r; }
    public function setTwoFactorCode($c) { $this->two_factor_code = $c; }
    public function setTwoFactorExpiresAt($d) { $this->two_factor_expires_at = $d; }
    public function setVerified($v) { $this->verified = $v; }
    public function setCreatedAt($d) { $this->created_at = $d; }
    public function setResetToken($t) { $this->reset_token = $t; }
    public function setResetExpiresAt($d) { $this->reset_expires_at = $d; }
}