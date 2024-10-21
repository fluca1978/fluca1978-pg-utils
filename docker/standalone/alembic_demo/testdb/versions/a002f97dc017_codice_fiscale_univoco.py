"""Codice fiscale univoco

Revision ID: a002f97dc017
Revises: 3d7495ef8b44
Create Date: 2024-07-24 13:06:40.837989

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = 'a002f97dc017'
down_revision: Union[str, None] = '3d7495ef8b44'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None



constraint_name = 'codice_fiscale_unique'

def upgrade() -> None:
    op.create_unique_constraint( constraint_name,
                                 'persona',
                                 [ 'codice_fiscale' ] )


def downgrade() -> None:
    op.drop_constraint( constraint_name,
                        'persona' )
