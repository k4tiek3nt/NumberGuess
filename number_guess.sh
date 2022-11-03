#!/bin/bash
# Program to guess a secret number between 1 and 1000
echo -e "\n~~ Number Guessing Game ~~"

PSQL="psql --username=freecodecamp --dbname=number_guess -t --no-align -c"

# get username from user
echo -e "\nEnter your username:"
read USERNAME

# query if username exists
USERNAME_RESULT=$($PSQL "SELECT username FROM user_info WHERE username='$USERNAME'")

# if username is not in db
if [[ -z $USERNAME_RESULT ]]
then
  # get next user id based on last entered in DB
  NEW_USER_ID=$($PSQL "SELECT COUNT(user_id) FROM user_info")

  # if no users exist
  if [[ -z $NEW_USER_ID ]]
  then
    # set user id to 7 because test script adds 1 - 6
    NEW_USER_ID = 7
  else
    # add 1 to the last user id in db
    ((NEW_USER_ID++))
  fi

  # insert the username into the db
  INSERT_USERNAME=$($PSQL "INSERT INTO user_info (user_id, username) values ($NEW_USER_ID, '$USERNAME')")    # Welcome the new user
  
  # welcome new user after inserting into db
  echo -e "\nWelcome, $USERNAME! It looks like this is your first time here."
    
  # get user_id for when the secret number is created
  USER_ID=$($PSQL "SELECT user_id FROM user_info WHERE username='$USERNAME'")
  
# if username is in db
else
  # get user id based on user name for next query
  USER_ID=$($PSQL "SELECT user_id FROM user_info WHERE username='$USERNAME'")

  # get the number of games played based on game_id
  GAMES_PLAYED=$($PSQL "SELECT COUNT(game_id) FROM game_info WHERE user_id=$USER_ID")

  # get best game - min guesses to guess right
  BEST_GAME=$($PSQL "SELECT MIN(number_of_guesses) FROM game_info WHERE user_id=$USER_ID")

  # Welcome the return user
  echo -e "\nWelcome back, $USERNAME! You have played $GAMES_PLAYED games, and your best game took $BEST_GAME guesses."
fi

SECRET_NUMBER=$[RANDOM%1000+1]
# insert the secret number into the db
INSERT_NEW_GAME=$($PSQL "INSERT INTO game_info (user_id, secret_number) values ('$USER_ID', $SECRET_NUMBER)")

# get game id for current game
GAME_ID=$($PSQL "SELECT MAX(game_id) FROM game_info WHERE user_id=$USER_ID")

# set count for guesses
GUESS_COUNT=0

# Ask user to guess the number
echo -e "\nGuess the secret number between 1 and 1000:"
read USER_GUESS

# update number of guesses
((GUESS_COUNT++))

# check if the guess was right
USER_GUESS_RESULT=$($PSQL "SELECT secret_number FROM game_info WHERE game_id=$GAME_ID AND user_id=$USER_ID AND secret_number=$USER_GUESS")

if [[ -z $USER_GUESS_RESULT ]]
then
  until [[ $USER_GUESS == $SECRET_NUMBER ]]
  do
    # if not a number
    if [[ ! $USER_GUESS =~ ^[0-9]+$ ]] 
    then
      echo -e "\nThat is not an integer, guess again:"
      read USER_GUESS

      # update number of guesses
      ((GUESS_COUNT++))  

    # if guess is lower than secret number
    elif [[ $USER_GUESS < $SECRET_NUMBER ]]
    then
      echo -e "\nIt's higher than that, guess again:"
      read USER_GUESS

      # update number of guesses
      ((GUESS_COUNT++))
     
    # if guess is higher than secret number
    else
      if [[ $USER_GUESS > $SECRET_NUMBER ]]
      then
        echo -e "\nIt's lower than that, guess again:"
        read USER_GUESS

        # update number of guesses
        ((GUESS_COUNT++))
                
      fi
    fi          
  done
fi

# if the guess is correct 
if [[ $USER_GUESS == $SECRET_NUMBER ]]
then
  # then update the game info to reflect number of guesses total
  UPDATE_GUESSES=$($PSQL "UPDATE game_info set number_of_guesses=$GUESS_COUNT WHERE game_id=$GAME_ID AND user_id=$USER_ID")

  # let user know they successfully guessed the secret number, how many guesses and what the number is
  echo -e "\nYou guessed it in $GUESS_COUNT tries. The secret number was $SECRET_NUMBER. Nice job!"
fi    